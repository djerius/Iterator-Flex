package Iterator::Flex::Base;

# ABSTRACT: Iterator object

use 5.10.0;

use strict;
use warnings;

use experimental qw( signatures declared_refs );

our $VERSION = '0.12';

use Scalar::Util;
use Ref::Util;
use List::Util;
use Role::Tiny       ();
use Role::Tiny::With ();
use Module::Runtime  ();

Role::Tiny::With::with 'Iterator::Flex::Role', 'Iterator::Flex::Role::Utils';

use Iterator::Flex::Utils qw ( :default :ExhaustionActions :RegistryKeys );
use Iterator::Flex::Failure;

use namespace::clean;

use overload ( '<>' => 'next', fallback => 1 );

# We separate constructor parameters into two categories:
#
#  1. those that are used to construct the iterator
#  2. those that specify what happens when the iterator signals exhaustion
#
#  Category #2 may be expanded. Category #2 parameters are *not* passed
#  to the iterator class construct* routines


sub new ( $class, $construct = undef, $general = {} ){
    return $class->new_from_attrs( $class->construct( $construct ), $general );
}

sub new_from_state {
    my ( $class, $state, $general ) = @_;
    return $class->new_from_attrs( $class->construct_from_state( $state ), $general );
}

sub new_from_attrs ( $class, $in_ipar = {}, $in_gpar = {} ) {

    my %ipar = $in_ipar->%*;
    my %gpar = $in_gpar->%*;

    $class->_validate_pars( \%ipar );

    my $roles = delete($ipar{_roles}) // [];

    unless ( Ref::Util::is_arrayref( $roles ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "_roles must be an arrayref" );
    }

    my @roles = ( $roles->@* );

    my $exhaustion_action = $gpar{ +EXHAUSTION } // [ RETURN, => undef ];

    my @exhaustion_action
      = Ref::Util::is_arrayref( $exhaustion_action )
      ? ( $exhaustion_action->@* )
      : ( $exhaustion_action );

    $gpar{+EXHAUSTION} = \@exhaustion_action;

    if ( $exhaustion_action[0] eq RETURN ) {
        push @roles, [ Exhaustion => 'Return' ];
    }
    elsif ( $exhaustion_action[0] eq THROW ) {

        push @roles,
          @exhaustion_action > 1 && $exhaustion_action[1] eq PASSTHROUGH
          ? [ Exhaustion => 'PassthroughThrow' ]
          : [ Exhaustion => 'Throw' ];
    }
    else {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "unknown exhaustion action: $exhaustion_action[0]" );
    }

    # push @roles, [ 'Exhausted', 'Registry' ];

    $class
      = Iterator::Flex::Utils::create_class_with_roles( $class, @roles );

    $ipar{_name} //= $class;

    my $self = bless $class->_construct_next( \%ipar, \%gpar ), $class;

    if ( exists $REGISTRY{ refaddr $self } ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "attempt to register an iterator subroutine which has already been registered."
        );
    }
    $REGISTRY{ refaddr $self } = { ITERATOR, => \%ipar, GENERAL, => \%gpar };

    $self->_reset_exhausted if $self->can( '_reset_exhausted' );

    return $self;
}

sub _validate_pars {

    my $class = shift;
    my $pars = shift;

    if ( defined( my $par = $pars->{_depends} ) ) {

        $pars->{_depends} = $par = [ $par ] unless Ref::Util::is_arrayref( $par );

        unless ( List::Util::all { $class->_is_iterator( $_ ) } $par->@* ) {
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
