package Iterator::Flex::Base;

# ABSTRACT: Iterator object

use strict;
use warnings;

our $VERSION = '0.11';

use Scalar::Util;
use Ref::Util;
use Role::Tiny       ();
use Role::Tiny::With ();
use Module::Runtime  ();

Role::Tiny::With::with 'Iterator::Flex::Role', 'Iterator::Flex::Role::Utils';

use Iterator::Flex::Utils;
use Iterator::Flex::Failure;

our %REGISTRY;

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
    my %attrs = ( _roles => [], %$attrs );
    $class->_validate_attrs( \%attrs );

    # add roles if necessary
    if ( @{ $attrs{_roles} } ) {

        $class->_croak( "_roles must be an arrayref" )
          unless Ref::Util::is_arrayref( $attrs{_roles} );

        $class = Iterator::Flex::Utils::create_class_with_roles( $class,
            @{ $attrs{_roles} } );
    }

    $attrs{name} = $class unless defined $attrs{name};

    my $self = bless $class->_construct_next( \%attrs ), $class;

    $REGISTRY{ Scalar::Util::refaddr $self } = \%attrs;

    $self->_reset_exhausted;

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
        delete $REGISTRY{ Scalar::Util::refaddr $_[0] };
    }
}



=method set_exhausted

  $iter->set_exhausted;

Set the iterator's state to exhausted

=cut

sub set_exhausted {
    my $attributes = $REGISTRY{ Scalar::Util::refaddr $_[0] };
    $attributes->{is_exhausted} = 1;
}

sub _reset_exhausted {
    my $attributes = $REGISTRY{ Scalar::Util::refaddr $_[0] };
    $attributes->{is_exhausted} = 0;
}


=method is_exhausted

  $bool = $iter->is_exhausted;

Returns true if the iterator is exhausted and there are no more values
available.  L<current> and L<next> will return C<undef>.  L<prev> will
return the last valid value returned by L<next>.

L<is_exhausted> is true only after L<next> has been called I<after>
the last valid value has been returned by a previous call to
L<next>. In other words, if C<$iter->next> returns the last valid
value, the state is still I<active>.  The next call to C<$iter->next>
will switch the iterator state to I<exhausted>.


=cut

sub is_exhausted {
    my $attributes = $REGISTRY{ Scalar::Util::refaddr $_[0] };
    !!$attributes->{is_exhausted};
}

=method __iter__

   $sub = $iter->__iter__;

Returns the subroutine which returns the next value from the iterator.

=cut

sub __iter__ {
    my $attributes = $REGISTRY{ Scalar::Util::refaddr $_[0] };
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

    my $attributes = shift
      // $Iterator::Flex::Base::REGISTRY{ Scalar::Util::refaddr $obj };

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
sub _load_role {
    my ( $class, $role ) = @_;

    for my $namespace ( $class->_namespaces ) {
        my $module = "${namespace}::Role::${role}";
        return $module if eval { Module::Runtime::require_module( $module ) };
    }

    _croak(
        "unable to find a module for role '$role' in @{[ join( ',', $class->_namespaces ) ]}"
    );
}

sub _add_roles {
    my $class = shift;

    Role::Tiny->apply_roles_to_package( $class,
        map { $class->_load_role( $_ ) } @_ );
}

1;

# COPYRIGHT
