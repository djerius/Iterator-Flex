package Iterator::Flex::Freeze;

# ABSTRACT:  Freeze an iterator after every next

use strict;
use warnings;

our $VERSION = '0.11';

use Iterator::Flex::Factory;
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

    my ( $class, $serialize, $src )  = ( shift, shift, shift );

    $class->_croak( "'serialize' must be a CODE reference" )
      unless Ref::Util::is_coderef( $serialize );

    $src = Iterator::Flex::Factory::to_iterator( $src );

    $class->_croak( "'src' iterator must provide a freeze method" )
      unless $class->_can_meth( $src, 'freeze' );

    my $self;
    my %params = (
        name => 'freeze',

        set_self => sub {
            $self = shift;
            Scalar::Util::weaken( $self );
        },

        depends => $src,
        next    => sub {
            my $value = $src->();
            local $_ = $src->freeze;
            &$serialize();
            $self->set_exhausted if $src->is_exhausted;
            $value;
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
      ExhaustedPredicate
] );

1;

# COPYRIGHT
