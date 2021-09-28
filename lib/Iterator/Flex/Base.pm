package Iterator::Flex::Base;

# ABSTRACT: Iterator object

use 5.10.0;

use strict;
use warnings;

use experimental qw( signatures declared_refs postderef );

our $VERSION = '0.12';

use Ref::Util;
use List::Util;
use Role::Tiny       ();
use Role::Tiny::With ();
use Module::Runtime  ();

Role::Tiny::With::with 'Iterator::Flex::Role', 'Iterator::Flex::Role::Utils';

use Iterator::Flex::Utils qw ( :default :ExhaustionActions :RegistryKeys );

use namespace::clean;

use overload ( '<>' => 'next', fallback => 1 );

# We separate constructor parameters into two categories:
#
#  1. those that are used to construct the iterator
#  2. those that specify what happens when the iterator signals exhaustion
#
#  Category #2 may be expanded. Category #2 parameters are *not* passed
#  to the iterator class construct* routines


sub new ( $class, $state = undef, $general = {} ){
    return $class->new_from_state( $state, $general );
}

sub new_from_state {
    my ( $class, $state, $general ) = @_;
    return $class->new_from_attrs( $class->construct( $state ), $general );
}

sub new_from_attrs ( $class, $in_ipar = {}, $in_gpar = {} ) {

    my %ipar = $in_ipar->%*;
    my %gpar = $in_gpar->%*;

    $class->_validate_pars( \%ipar );

    my $roles = delete( $ipar{_roles} ) // [];

    $class->throw( parameter => "_roles must be an arrayref" )
      unless Ref::Util::is_arrayref( $roles );

    my @roles = ( $roles->@* );

    my $exhaustion_action = $gpar{ +EXHAUSTION } // [ RETURN, => undef ];

    my @exhaustion_action
      = Ref::Util::is_arrayref( $exhaustion_action )
      ? ( $exhaustion_action->@* )
      : ( $exhaustion_action );

    $gpar{ +EXHAUSTION } = \@exhaustion_action;

    if ( $exhaustion_action[0] eq RETURN ) {
        push @roles, 'Exhaustion::Return';
    }
    elsif ( $exhaustion_action[0] eq THROW ) {

        push @roles,
          @exhaustion_action > 1 && $exhaustion_action[1] eq PASSTHROUGH
          ? 'Exhaustion::PassthroughThrow'
          : 'Exhaustion::Throw';
    }
    else {
        $class->_throw(
            parameter => "unknown exhaustion action: $exhaustion_action[0]" );
    }

    # push @roles, 'Exhausted::Registry';

    if ( defined( my $par = $ipar{+METHODS} ) ) {

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
            my $role = eval { Iterator::Flex::Method::Maker( $cap_name, name => $name ) };

            if ( $@ ne '' ) {
                my $error = $@;
                die $error
                  unless Ref::Util::is_blessed_ref( $error )
                  && $error->isa( 'Iterator::Flex::Failure::RoleExists' );
                $role = $error->payload;
            }

            push @roles, '+' . $role;  # need '+', as these are fully qualified role module names.
        }
    }

    $class = Iterator::Flex::Utils::create_class_with_roles( $class, @roles );

    $ipar{_name} //= $class;

    my $self = bless $class->_construct_next( \%ipar, \%gpar ), $class;

    $class->_throw( parameter =>
          "attempt to register an iterator subroutine which has already been registered."
    ) if exists $REGISTRY{ refaddr $self };

    $REGISTRY{ refaddr $self } = { ITERATOR, => \%ipar, GENERAL, => \%gpar };

    $self->_reset_exhausted if $self->can( '_reset_exhausted' );

    return $self;
}

sub _validate_pars {

    my $class = shift;
    my $pars  = shift;

    if ( defined( my $par = $pars->{_depends} ) ) {

        $pars->{_depends} = $par = [$par] unless Ref::Util::is_arrayref( $par );
        $class->_throw( parameter => "dependency #$_ is not an iterator object" )
          unless List::Util::all { $class->_is_iterator( $_ ) } $par->@*;
    }

    return;
}

sub DESTROY {

    if ( defined $_[0] ) {
        delete $REGISTRY{ refaddr $_[0] };
    }
}

sub _name {
    $REGISTRY{ refaddr $_[0] }{ +ITERATOR }{_name};
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
    return $REGISTRY{ refaddr $_[0] }{+ITERATOR}{next};
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
      ? !List::Util::first { !$_->may( $meth ) } $attributes->{_depends}->@*
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
    return 'Iterator::Flex';
}

sub _role_namespaces {
    return 'Iterator::Flex::Role';
}


# return the role name for a given method
sub _add_roles {
    my $class = shift;
    Role::Tiny->apply_roles_to_package( $class,
        map { $class->_load_role( $_ ) } @_ );
}

sub _apply_method_to_depends {
    my ( $self, $meth ) = @_;

    if ( defined ( my $depends = $REGISTRY{ refaddr $self }{ +ITERATOR }{_depends} ) ) {
        # first check if dependencies have method
        my $cant = List::Util::first { !$_->can( $meth ) } $depends->@*;
        $self->_throw( parameter =>
              "dependency: @{[ $cant->_name ]} does not have a '$meth' method"
        ) if $cant;

        # now apply the method
        $_->$meth foreach $depends->@*;
    }

}

1;

# COPYRIGHT
