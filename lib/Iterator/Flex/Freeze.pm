package Iterator::Flex::Freeze;

# ABSTRACT:  Freeze an iterator after every next

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Factory;
use Iterator::Flex::Utils qw( RETURN EXHAUSTION );
use parent 'Iterator::Flex::Base';
use Scalar::Util;
use Ref::Util;

=method construct

  $iter = Iterator::Flex::Freeze->new( $coderef, $iterator );

Construct a pass-through iterator which freezes the input iterator
after every call to C<next>.  C<$coderef> will be passed the frozen state
(generated by calling C<$iterator->freeze> via C<$_>, with which it
can do as it pleases.

<$coderef> I<is> executed when C<$iterator> returns I<undef> (that is,
when C<$iterator> is exhausted).

The returned iterator supports the following methods:

=over

=item next

=item prev

If C<$iterator> provides a C<prev> method.

=item rewind

=item freeze

=back

=cut


sub construct {

    my $class = shift;

    unless ( @_ == 1 && Ref::Util::is_arrayref( $_[0] ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "incorrect type or number of arguments" );
    }

    my ( $serialize, $src ) = @{$_[0]};


    if ( ! Ref::Util::is_coderef( $serialize ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "'serialize' must be a CODE reference" );
    }

    $src = Iterator::Flex::Factory->to_iterator( $src, { EXHAUSTION ,=> RETURN } );

    unless ( $class->_can_meth( $src, 'freeze' ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "'src' iterator must provide a freeze method" );
    }

    unless ( $class->_can_meth( $src, 'set_exhausted' )
        && $class->_can_meth( $src, 'is_exhausted' ) )
    {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "'src' iterator must provide set_exhausted/is_exhausted methods" );
    }

    my $self;
    my %params = (
        _name => 'freeze',

        _self => \$self,

        _depends => $src,
        next    => sub {
            my $value = $src->();
            local $_ = $src->freeze;
            &$serialize();
            $value = $self->signal_exhaustion if $src->is_exhausted;
            return $value;
        },
    );

    Scalar::Util::weaken $src;
    $params{_roles} = [];
    for my $meth ( 'prev', 'current', 'rewind', 'reset' ) {
        next unless $src->_may_meth( $meth );
        my $sub = $src->can( $meth );
        Scalar::Util::weaken $sub;
        $params{$meth} = sub {
            $src->$sub();
        };
        push @{ $params{_roles} }, $class->_load_role( ucfirst $meth );
    }


    return \%params;
}

__PACKAGE__->_add_roles( qw[
      ::Exhausted::Registry
      ::Next::ClosedSelf
      Next
] );

1;

# COPYRIGHT
