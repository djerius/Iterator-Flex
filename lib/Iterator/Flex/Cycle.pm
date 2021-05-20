package Iterator::Flex::Cycle;

# ABSTRACT: Array Cycle Iterator Class

use strict;
use warnings;

our $VERSION = '0.12';

use parent 'Iterator::Flex::Base';
use Ref::Util;

=method new

  $iterator = Iterator::Flex::Cycle->new( $array_ref );

Wrap an array in an iterator which will cycle continuously through it.
The iterator is never exhausted.

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

    $class->construct_from_state( { array => $_[0] } );
}

sub construct_from_state {

    my ( $class, $state ) = ( shift, shift );

    unless ( Ref::Util::is_hashref( $state ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "state must be a HASH reference" );
    }

    my ( $arr, $prev, $current, $next )
      = @{$state}{qw[ array prev current next ]};

    unless ( Ref::Util::is_arrayref( $arr ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "argument must be an ARRAY reference" );
    }

    my $len = @$arr;

    $next = 0 unless defined $next;

    if ( defined $prev && ( $prev < 0 || $prev >= $len ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw( "illegal value for 'prev'" );
    }

    if ( defined $current && ( $current < 0 || $current >= $len ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "illegal value for 'current'" );
    }

    if ( $next < 0 || $next > $len ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw( "illegal value for 'next'" );
    }

    return {

        reset => sub {
            $prev = $current = undef;
            $next = 0;
        },

        rewind => sub {
            $next = 0;
        },

        prev => sub {
            return defined $prev ? $arr->[$prev] : undef;
        },

        current => sub {
            return defined $current ? $arr->[$current] : undef;
        },

        next => sub {
            $next    = 0 if $next == $len;
            $prev    = $current;
            $current = $next++;
            return $arr->[$current];
        },

        freeze => sub {
            return [
                $class,
                {
                    array   => $arr,
                    prev    => $prev,
                    current => $current,
                    next    => $next,
                },
            ];
        },
    };
}


__PACKAGE__->_add_roles( qw[
      ::Next::NoSelf
      Next
      Rewind
      Reset
      Prev
      Current
      Freeze
] );


1;

# COPYRIGHT
