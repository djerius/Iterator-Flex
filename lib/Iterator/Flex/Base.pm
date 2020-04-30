package Iterator::Flex::Base;

# ABSTRACT: Iterator object

use 5.10.0;

use strict;
use warnings;

our $VERSION = '0.11';

use Scalar::Util;
use Ref::Util;
use Role::Tiny       ();
use Role::Tiny::With ();
use Module::Runtime  ();

Role::Tiny::With::with 'Iterator::Flex::Role', 'Iterator::Flex::Role::Utils';

use Iterator::Flex::Utils qw ( :default :ExhaustionActions );
use Iterator::Flex::Failure;

use namespace::clean;

use overload ( '<>' => 'next', fallback => 1 );

sub _croak {
    my $class = ref $_[0] || $_[0];
    shift;
    require Carp;
    Carp::croak( "$class: ", @_ );
}

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
    $class->_croak( "_roles must be an arrayref" )
      unless Ref::Util::is_arrayref( $roles );

    $class->_croak( "specify only one output exhaustion action" )
      if 1 < ( my ( $exhaustion_action )
          = grep { exists $attr{$_} } @ExhaustionActions );

    # default to returning undef on exhaustion
    if ( !defined $exhaustion_action ) {
        $exhaustion_action = ON_EXHAUSTION_RETURN;
        $attr{ +ON_EXHAUSTION_RETURN } = undef;
    }

    if ( $exhaustion_action eq ON_EXHAUSTION_RETURN ) {
        push @{$roles}, [ Exhaustion => 'Return' ];
        $attr{ +ON_EXHAUSTION_RETURN } = delete $attr{$exhaustion_action};
    }
    elsif ( $exhaustion_action eq 'on_exhaustion_throw' ) {

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

    $attr{name} = delete $attr{name} // $class;

    my $self = bless $class->_construct_next( \%attr ), $class;


    $self->_croak(
        "attempt to register an iterator subroutine which has already been registered."
    ) if exists $REGISTRY{ refaddr $self };

    $REGISTRY{ refaddr $self } = \%attr;

    $self->_reset_exhausted if $self->can( '_reset_exhausted' );

    return $self;
}

sub _validate_attrs {

    my $class = shift;
    my $attrs = shift;

    # FIXME - don't copy until it's actually needed.
    my %iattr = %$attrs;
    my $attr;

    if ( defined( $attr = delete $iattr{depends} ) ) {

        $attr = [$attr] unless Ref::Util::is_arrayref( $attr );
        $attrs->{depends} = $attr;

# FIXME: this is too restrictive. It should allow simple coderefs, or things with a next or __next__ .
        $class->_croak( "dependency #$_ is not an iterator object\n" )
          for grep {
            !( Scalar::Util::blessed( $attr->[$_] )
                && $attr->[$_]->isa( __PACKAGE__ ) )
          } 0 .. $#{$attr};
    }

    return;
}

sub DESTROY {

    if ( defined $_[0] ) {
        delete $REGISTRY{ refaddr $_[0] };
    }
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
      defined $attributes->{depends}
      ? !List::Util::first { !$_->may( $meth ) } @{ $attributes->{depends} }
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
