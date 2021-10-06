package Iterator::Flex::Base;

# ABSTRACT: Iterator object

use 5.10.0;

use strict;
use warnings;

use experimental qw( signatures postderef );

our $VERSION = '0.13';

use Ref::Util;
use List::Util;
use Role::Tiny       ();
use Role::Tiny::With ();
use Module::Runtime  ();

Role::Tiny::With::with 'Iterator::Flex::Role', 'Iterator::Flex::Role::Utils';

use Iterator::Flex::Utils qw (
  :default
  :ExhaustionActions
  :RegistryKeys
  :IterAttrs
  :IterStates
  check_invalid_interface_parameters
  check_invalid_signal_parameters
);

use namespace::clean;

use overload ( '<>' => sub ( $self, $, $ ) { &{$self} }, fallback => 1 );

# We separate constructor parameters into two categories:
#
#  1. those that are used to construct the iterator
#  2. those that specify what happens when the iterator signals exhaustion
#
#  Category #2 may be expanded. Category #2 parameters are *not* passed
#  to the iterator class construct* routines


sub new ( $class, $state = undef, $general = {} ) {
    return $class->new_from_state( $state, $general );
}

sub new_from_state ( $class, $state, $general ) {
    return $class->new_from_attrs( $class->construct( $state ), $general );
}

sub new_from_attrs ( $class, $in_ipar = {}, $in_gpar = {} ) {

    my %ipar = $in_ipar->%*;
    my %gpar = $in_gpar->%*;

    $class->_validate_interface_pars( \%ipar );
    $class->_validate_signal_pars( \%gpar );

    my @roles = ( delete( $ipar{ +_ROLES } ) // [] )->@*;

    $gpar{ +ERROR } //= [ ( +THROW ) ];
    $gpar{ +ERROR } = [ $gpar{ +ERROR } ]
      unless Ref::Util::is_arrayref( $gpar{ +ERROR } );

    if ( $gpar{ +ERROR }[0] eq +THROW ) {
        push @roles, 'Error::Throw';
    }
    else {
        $class->_throw(
            "unknown specification of iterator error signaling behavior:",
            $gpar{ +ERROR }[0] );
    }

    my $exhaustion_action = $gpar{ +EXHAUSTION } // [ ( +RETURN ) => undef ];

    my @exhaustion_action
      = Ref::Util::is_arrayref( $exhaustion_action )
      ? ( $exhaustion_action->@* )
      : ( $exhaustion_action );

    $gpar{ +EXHAUSTION } = \@exhaustion_action;

    if ( $exhaustion_action[0] eq +RETURN ) {
        push @roles, 'Exhaustion::Return';
    }
    elsif ( $exhaustion_action[0] eq +THROW ) {

        push @roles,
          @exhaustion_action > 1 && $exhaustion_action[1] eq +PASSTHROUGH
          ? 'Exhaustion::PassthroughThrow'
          : 'Exhaustion::Throw';
    }
    else {
        $class->_throw(
            parameter => "unknown exhaustion action: $exhaustion_action[0]" );
    }

    if ( defined( my $par = $ipar{ +METHODS } ) ) {

        require Iterator::Flex::Method;

        $class->_throw( parameter =>
              "value for methods parameter must be a hash reference" )
          unless Ref::Util::is_hashref( $par );

        for my $name ( keys $par->%* ) {

            my $code = $par->{$name};

            $class->_throw( parameter =>
                  "value for 'methods' parameter key '$name' must be a code reference"
            ) unless Ref::Util::is_coderef( $code );

            my $cap_name = ucfirst( $name );

            # create role for the method
            my $role
              = eval { Iterator::Flex::Method::Maker( $cap_name, name => $name ) };

            if ( $@ ne '' ) {
                my $error = $@;
                die $error
                  unless Ref::Util::is_blessed_ref( $error )
                  && $error->isa( 'Iterator::Flex::Failure::RoleExists' );
                $role = $error->payload;
            }

            push @roles,
              '+'
              . $role
              ;    # need '+', as these are fully qualified role module names.
        }
    }

    $class = Iterator::Flex::Utils::create_class_with_roles( $class, @roles );

    $ipar{ +_NAME } //= $class;

    my $self = bless $class->_construct_next( \%ipar, \%gpar ), $class;

    $class->_throw( parameter =>
          "attempt to register an iterator subroutine which has already been registered."
    ) if exists $REGISTRY{ refaddr $self };

    $REGISTRY{ refaddr $self }
      = { ( +ITERATOR ) => \%ipar, ( +GENERAL ) => \%gpar };

    $self->_clear_state;

    return $self;
}

sub _validate_interface_pars ( $class, $pars ) {

    my @bad = check_invalid_interface_parameters( [ keys $pars->%* ] );

    $class->_throw( parameter => "unknown interface parameters: @{[ join ', ', @bad ]}" )
      if @bad;

    $class->_throw( parameter => "@{[ +_ROLES ]}  must be an arrayref" )
      if defined $pars->{+_ROLES} && ! Ref::Util::is_arrayref( $pars->{+_ROLES} );

    if ( defined( my $par = $pars->{+_DEPENDS} ) ) {
        $pars->{+_DEPENDS} = $par = [$par] unless Ref::Util::is_arrayref( $par );
        $class->_throw(
            parameter => "dependency #$_ is not an iterator object" )
          unless List::Util::all { $class->_is_iterator( $_ ) } $par->@*;
    }

    return;
}

sub _validate_signal_pars( $class, $pars ) {

    my @bad = check_invalid_signal_parameters( [ keys $pars->%* ] );

    $class->_throw( parameter => "unknown signal parameters: @{[ join ', ', @bad ]}" )
      if @bad;
}


sub DESTROY ( $self ) {

    if ( defined $self ) {
        delete $REGISTRY{ refaddr $self };
    }
}

sub _name ( $self ) {
    $REGISTRY{ refaddr $self }{ +ITERATOR }{ +_NAME };
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

sub _is_iterator ( $, $obj ) {
    return Ref::Util::is_blessed_ref( $obj ) && $obj->isa( __PACKAGE__ );
}

=method __iter__

   $sub = $iter->__iter__;

Returns the subroutine which returns the next value from the iterator.

=cut

sub __iter__ ( $self ) {
    return $REGISTRY{ refaddr $self }{ +ITERATOR }{ +NEXT };
}

=method may

  $bool = $iter->may( $method );

Similar to L<can|UNIVERSAL/can>, except it checks that the method can
be called on the iterators which C<$iter> depends on.  For example,
it's possible that C<$iter> implements a C<rewind> method, but that
it's dependencies do not.  In that case L<can|UNIVERSAL/can> will
return true, but C<may> will return false.

=cut

sub may ( $self, $meth, $attributes = $self->__regentry( +ITERATOR ) ) {

    return $attributes->{"_may_$meth"}
      //= defined $attributes->{ +_DEPENDS }
      ? !List::Util::first { !$_->may( $meth ) } $attributes->{ +_DEPENDS }->@*
      : 1;
}

=method _namespaces

 @namespaces = $class->_namespaces;

Returns a list of namespaces to search for classes.  When called on the base class,
this returns

 Iterator::Flex

=cut

sub _namespaces {
    return 'Iterator::Flex';
}

=method _role_namespaces

 @namespaces = $class->_role_namespaces;

Returns a list of namespaces to search for roles.  When called on the base class,
returns

 Iterator::Flex::Role

=cut

sub _role_namespaces {
    return 'Iterator::Flex::Role';
}


=method _add_roles

  $class->_add_roles( @roles );

Add roles to the class. If the name begins with a C<+>, it is assumed
to be a fully qualified name, otherwise it is searched for in the
namespaces returned by the C<<
L<_role_namespaces|Iterator::Flex::Base/_role_namespaces> >> class
method.

=cut

sub _add_roles ( $class, @roles ) {
    Role::Tiny->apply_roles_to_package( $class,
        map { $class->_load_role( $_ ) } @roles );
}

sub _apply_method_to_depends ( $self, $meth ) {

    if (
        defined(
            my $depends = $REGISTRY{ refaddr $self }{ +ITERATOR }{ +_DEPENDS } )
      )
    {
        # first check if dependencies have method
        my $cant = List::Util::first { !$_->can( $meth ) } $depends->@*;
        $self->_throw( Unsupported =>
              "dependency: @{[ $cant->_name ]} does not have a '$meth' method" )
          if $cant;

        # now apply the method
        $_->$meth foreach $depends->@*;
    }
}

=method is_exhausted

An object method which returns true if the iterator is in the
L<exhausted state|Iterator::Flex::Manual::Overview/Exhausted State>

=cut

sub is_exhausted ( $self ) {
    $self->get_state == +IterState_EXHAUSTED;
}

=method set_exhausted

I<Internal method.>

An object method which sets the iterator state status to
L<exhausted|Iterator::Flex::Manual::Overview/Exhausted State>.

It does I<not> signal exhaustion.

=cut

sub set_exhausted ( $self ) {
    $self->set_state( +IterState_EXHAUSTED );
}

=begin internal

=method _clear_state

I<Internal method.>

An  object method which clears the state status.  After
this call, this will hold:

  $iter->is_error => false
  $iter->is_exhausted => false

=end internal

=cut

sub _clear_state ( $self ) {
    $self->set_state( +IterState_CLEAR );
}

=method is_error

An object method which returns true if the iterator is in the
L<error state|Iterator::Flex::Manual::Overview/Error State>

=cut

sub is_error ( $self ) {
    $_[0]->get_state == +IterState_ERROR;
}

=method set_error

I<Internal method.>

An object method which sets the iterator state status to
L<error|Iterator::Flex::Manual::Overview/Error State>.

It does I<not> signal error.

=cut

sub set_error ( $self ) {
    $self->set_state( +IterState_ERROR );
}

sub __regentry ( $self, @keys ) {
    my $entry = $REGISTRY{ refaddr $self };
    $entry = $entry->{ shift @keys } while @keys;
    return $entry;
}


1;

# COPYRIGHT
