package Iterator::Flex::Base;

# ABSTRACT: Iterator object

use 5.10.0;

use strict;
use warnings;

our $VERSION = '0.12';

use Scalar::Util;
use Ref::Util;
use List::Util;
use Role::Tiny       ();
use Role::Tiny::With ();
use Module::Runtime  ();

Role::Tiny::With::with 'Iterator::Flex::Role', 'Iterator::Flex::Role::Utils';

use Iterator::Flex::Utils qw ( :default :ExhaustionActions );
use Iterator::Flex::Failure;

use namespace::clean;

use overload ( '<>' => 'next', fallback => 1 );

sub new {
    my $class = shift;
    return $class->new_from_attrs( $class->construct( @_ ) );
}

sub new_from_state {
    my $class = shift;
    return $class->new_from_attrs( $class->construct_from_state( @_ ) );
}

sub new_from_attrs {

    my ( $class, $attrs ) = ( shift, shift );

    # copy attrs as we may change it
    my %attr = ( _roles => [], %$attrs );

    $class->_validate_attrs( \%attr );

    my $roles = delete( $attr{_roles} ) // [];
    unless ( Ref::Util::is_arrayref( $roles ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "_roles must be an arrayref" );
    }

    my ( $exhaustion_action, @rest )
              = grep { exists $attr{$_} } @ExhaustionActions;

    if ( @rest ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "specify only one output exhaustion action" );
    }

    # default to returning undef on exhaustion
    if ( !defined $exhaustion_action ) {
        $exhaustion_action = ON_EXHAUSTION_RETURN;
        $attr{ +ON_EXHAUSTION_RETURN } = undef;
    }

    if ( $exhaustion_action eq ON_EXHAUSTION_RETURN ) {
        push @{$roles}, [ Exhaustion => 'Return' ];
        $attr{ +ON_EXHAUSTION_RETURN } = delete $attr{$exhaustion_action};
    }
    elsif ( $exhaustion_action eq ON_EXHAUSTION_THROW ) {

        if ( $attr{ +ON_EXHAUSTION_THROW } eq ON_EXHAUSTION_PASSTHROUGH ) {
            push @{$roles}, [ Exhaustion => 'PassthroughThrow' ];
        }
        else {
            $attr{ +ON_EXHAUSTION_THROW } = delete $attr{$exhaustion_action};
            push @{$roles}, [ Exhaustion => 'Throw' ];
        }
    }

    push @{$roles}, 'Exhausted';

    $class
      = Iterator::Flex::Utils::create_class_with_roles( $class, @{$roles} );

    $attr{_name} = delete $attr{_name} // $class;

    my $self = bless $class->_construct_next( \%attr ), $class;


    if ( exists $REGISTRY{ refaddr $self } ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "attempt to register an iterator subroutine which has already been registered."
        );
    }
    $REGISTRY{ refaddr $self } = \%attr;

    $self->_reset_exhausted if $self->can( '_reset_exhausted' );

    return $self;
}

sub _validate_attrs {

    my $class = shift;
    my $attrs = shift;

    if ( defined( my $attr = $attrs->{_depends} ) ) {

        $attrs->{_depends} = $attr = [ $attr ] unless Ref::Util::is_arrayref( $attr );

        unless ( List::Util::all { $class->_is_iterator( $_ ) } $attr->@* ) {
            require Iterator::Flex::Failure;
            Iterator::Flex::Failure::parameter->throw(
                "dependency #$_ is not an iterator object\n" );
        }
    }

    return;
}

sub DESTROY {

    if ( defined $_[0] ) {
        delete $REGISTRY{ refaddr $_[0] };
    }
}


=method _is_iterator

  $class->_is_iterator( $obj  );

Returns true if an object is an iterator, where iterator is defined as

=over

=item *

An object which inherits from L<Iterator::Flex::Base>.

=back

=cut

# TODO: this is too restrictive. It should allow simple coderefs, or
# things with a next or __next__.

sub _is_iterator {
    my ( $class, $obj ) = @_;
    return Ref::Util::is_blessed_ref( $obj ) && $obj->isa( __PACKAGE__ );
}

=method __iter__

   $sub = $iter->__iter__;

Returns the subroutine which returns the next value from the iterator.

=cut

sub __iter__ {
    my $attributes = $REGISTRY{ refaddr $_[0] };
    $attributes->{next};
}

=method may

  $bool = $iter->may( $method );

Similar to L<can|UNIVERSAL/can>, except it checks to ensure that the
method can be called on the iterators which C<$iter> depends on.  For
example, it's possible that C<$iter> implements a C<rewind> method,
but that it's dependencies do not.  In that case C<can|UNIVESAL/can>
will return true, but C<may> will return false.

=cut

sub may {
    return undef;
}

sub _may_meth {

    my $obj  = shift;
    my $meth = shift;

    my $attributes = shift // $REGISTRY{ refaddr $obj };

    my $pred = "_may_$meth";

    $attributes->{$pred} //=
      defined $attributes->{_depends}
      ? !List::Util::first { !$_->may( $meth ) } @{ $attributes->{_depends} }
      : 1;

    return $attributes->{$pred};
}

sub _wrap_may {

    # my $class  = shift;
    shift;
    my $meth = shift;

    return sub {
        my $orig = shift;
        my ( $obj, $what ) = @_;

        return $obj->_may_meth( $meth )
          if $what eq $meth;

        &$orig;
    };

}

sub _namespaces {
    my $class = shift;
    ( my $namespace ) = $class =~ /(.*)::[^:]+$/;
    return ( $namespace, 'Iterator::Flex' );
}


# return the role name for a given method
sub _add_roles {
    my $class = shift;
    Role::Tiny->apply_roles_to_package( $class,
        map { $class->_load_role( $_ ) } @_ );
}

1;

# COPYRIGHT
