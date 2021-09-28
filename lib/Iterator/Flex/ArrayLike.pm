package Iterator::Flex::ArrayLike;

# ABSTRACT: ArrayLike Iterator Class

use strict;
use warnings;

our $VERSION = '0.12';

use Ref::Util;
use Iterator::Flex::Utils ':IterAttrs';
use namespace::clean;

use parent 'Iterator::Flex::Base';
use Role::Tiny::With ();
Role::Tiny::With::with 'Iterator::Flex::Role::Utils';


=method new

  $iterator = Iterator::Flex::ArrayLike->new( $obj, %ipars, \%gpars );

Wrap an array-like object in an iterator.  An array like object must
provide two methods, one which returns the number of elements, and
another which returns the element at a given index.

The following parameters are available:

=over

=item length => I<method name>

=item length => I<coderef>

The supplied argument will be used to determine the number of elements, via

   $nelem = $obj->$length;

If not specified, a method with name C<length> or C<__length__> or
C<len> or C<__len__> will be used if the object provides it.

=item at => I<method name>

=item at => I<coderef>

The supplied argument will be used to obtain the element at a specified index.

   $element = $obj->$at( $index );

If not specified, a method with name C<at> or C<__at__>, or C<getitem>
or C<__getitem__> will be used if the object provides it.

=back

The returned iterator supports the following methods:

=over

=item current

=item next

=item prev

=item rewind

=item reset

=item freeze

=back

=cut

sub new {
    my $class = shift;
    my $gpar = Ref::Util::is_hashref( $_[-1] ) ? pop : {};

    my ( $obj, %ipar ) = @_;
    $ipar{ object } = $obj;

    $class->_croak( parameter => "argument must be a blessed reference" )
      unless Ref::Util::is_blessed_ref( $obj );

    $class->SUPER::new( \%ipar, $gpar );
}

sub construct {

    my ( $class, $state ) = @_;

    $class->_throw( parameter => "state must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $obj, $prev, $current, $next, $length, $at )
      = @{$state}{qw[ object prev current next length at ]};

    $class->_throw(
        parameter => "state 'object' argument must be a blessed reference" )
      unless Ref::Util::is_blessed_ref( $obj );

    $length = $class->_resolve_meth( $obj, $length, 'length', 'len' );

    $at = $class->_resolve_meth( $obj, $at, 'at', 'getitem' );

    my $len = $obj->$length;

    $next = 0 unless defined $next;

    $class->_throw( parameter => "illegal value for state 'prev' argument" )
      if defined $prev && ( $prev < 0 || $prev >= $len );

    $class->_throw( parameter => "illegal value for state 'current' argument" )
      if defined $current && ( $current < 0 || $current >= $len );

    $class->_throw( parameter => "illegal value for state 'next' argument" )
      if $next < 0 || $next > $len;

    my $self;

    return {

        _SELF ,=> \$self,

        RESET ,=> sub {
            $prev = $current = undef;
            $next = 0;
        },

        REWIND ,=> sub {
            $next = 0;
        },

        PREV ,=> sub {
            return defined $prev ? $obj->$at( $prev ) : undef;
        },

        CURRENT ,=> sub {
            return defined $current ? $obj->$at( $current ) : undef;
        },

        NEXT ,=> sub {
            if ( $next == $len ) {
                # if first time through, set current
                $prev = $current
                  if ! $self->is_exhausted;
                return $current = $self->signal_exhaustion;
            }
            $prev    = $current;
            $current = $next++;

            return $obj->$at( $current );
        },
    };
}


__PACKAGE__->_add_roles( qw[
      Exhausted::Registry
      Next::ClosedSelf
      Rewind::Closure
      Reset::Closure
      Prev::Closure
      Current::Closure
] );

1;

# COPYRIGHT
