package Iterator::Flex::ArrayLike;

# ABSTRACT: ArrayLike Iterator Class

use strict;
use warnings;

our $VERSION = '0.12';

use parent 'Iterator::Flex::Base';
use Role::Tiny::With ();
Role::Tiny::With::with 'Iterator::Flex::Role::Utils';

use Ref::Util;

=for stopwords attr

=method new

  $iterator = Iterator::Flex::ArrayLike->new( $obj, %args );

Wrap an array-like object in an iterator.  An array like object must
provide two methods, one which returns the number of elements, and
another which returns the element at a given index.

The following arguments are available:

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

sub construct {
    my $class = shift;

    unless ( Ref::Util::is_blessed_ref( $_[0] ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw( "argument must be a blessed reference" );
    }

    $class->construct_from_state( { object => @_ } );
}

sub construct_from_state {

    my ( $class, $state ) = @_;

    unless ( Ref::Util::is_hashref( $state ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "state must be a HASH reference" );
    }

    my ( $obj, $prev, $current, $next, $length, $at )
      = @{$state}{qw[ object prev current next ]};

    unless ( Ref::Util::is_blessed_ref( $obj ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "state 'object' argument must be a blessed reference" );
    }

    $length //= _can_meth( $obj, 'length' ) // _can_meth( $obj, 'len' ) // do {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "no 'length' method defined or discovered" );
    };

    $at //= _can_meth( $obj, 'at' ) // _can_meth( $obj, 'getitem' ) // do {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "no 'at' method defined or discovered" );
    };

    my $len = $obj->$length;

    $next = 0 unless defined $next;

    if ( defined $prev && ( $prev < 0 || $prev >= $len ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "illegal value for state 'prev' argument" );
    }

    if ( defined $current && ( $current < 0 || $current >= $len ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "illegal value for state 'current' argument" );
    }

    if ( $next < 0 || $next > $len ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "illegal value for state 'next' argument" );
    }

    my $self;

    return {

        _self => \$self,

        reset => sub {
            $prev = $current = undef;
            $next = 0;
        },

        rewind => sub {
            $next = 0;
        },

        prev => sub {
            return defined $prev ? $obj->$at( $prev ) : undef;
        },

        current => sub {
            return defined $current ? $obj->$at( $current ) : undef;
        },

        next => sub {
            if ( $next == $len ) {
                # if first time through, set current/prev
                if ( !$self->is_exhausted ) {
                    $prev    = $current;
                    $current = $self->signal_exhaustion;
                }
                return $current;
            }
            $prev    = $current;
            $current = $next++;

            return $obj->$at( $current );
        },
    };
}


__PACKAGE__->_add_roles( qw[
      Next::ClosedSelf
      Next
      Rewind
      Reset
      Prev
      Current
] );

1;

# COPYRIGHT