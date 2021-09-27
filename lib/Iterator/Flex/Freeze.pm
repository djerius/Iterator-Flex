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

use namespace::clean;

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


sub new {
    my $class = shift;
    my $gpar = Ref::Util::is_hashref( $_[-1] ) ? pop : {};

    $class->_throw( parameter => 'not enough parameters' )
      unless @_ == 2;

    $class->_throw( parameter => "'serialize' parameter is not a coderef" )
      unless Ref::Util::is_coderef( $_[0] );

    $class->SUPER::new( { serialize => $_[0], src => $_[1] }, $gpar );
}


sub construct {
    my ( $class, $state ) = @_;

    $class->_throw( parameter => "'state' parameter must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $serialize, $src ) = @{$state}{ qw( serialize src ) };

    $class->_throw( parameter => "'serialize' must be a CODE reference" )
      unless Ref::Util::is_coderef( $serialize );

    $src
      = Iterator::Flex::Factory->to_iterator( $src, { EXHAUSTION, => RETURN } );

    $class->_throw( parameter => "'src' iterator must provide a freeze method" )
      unless $class->_can_meth( $src, 'freeze' );

    $class->_throw( parameter =>
          "'src' iterator must provide set_exhausted/is_exhausted methods" )
      unless $class->_can_meth( $src, 'set_exhausted' )
      && $class->_can_meth( $src, 'is_exhausted' );

    my $self;
    my %params = (
        _name => 'freeze',

        _self => \$self,

        _depends => $src,
        next     => sub {
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
        # need '+' as role names are fully qualified
        push @{ $params{_roles} }, '+' . $class->_load_role( ucfirst $meth );
    }


    return \%params;
}

__PACKAGE__->_add_roles( qw[
      Exhausted::Registry
      Next::ClosedSelf
      Next
] );

1;

# COPYRIGHT
