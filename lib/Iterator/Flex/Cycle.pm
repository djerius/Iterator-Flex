package Iterator::Flex::Cycle;

# ABSTRACT: Array Cycle Iterator Class

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.13';

use Iterator::Flex::Utils ':IterAttrs';
use Ref::Util;
use namespace::clean;

use parent 'Iterator::Flex::Base';

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

sub new ( $class, $array, $ ) {

    $class->_throw( parameter => "argument must be an ARRAY reference" )
      unless Ref::Util::is_arrayref( $array );

    $class->SUPER::new( { array => $array }, {} );
}

sub construct ( $class, $state ) {

    $class->_throw( parameter => "state must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $arr, $prev, $current, $next )
      = @{$state}{qw[ array prev current next ]};

    my $len = @$arr;

    $next = 0 unless defined $next;

    $class->_throw( parameter => "illegal value for 'prev'" )
      if defined $prev && ( $prev < 0 || $prev >= $len );

    $class->_throw( parameter => "illegal value for 'current'" )
      if defined $current && ( $current < 0 || $current >= $len );

    $class->_throw( parameter => "illegal value for 'next'" )
      if $next < 0 || $next > $len;


    return {

        (+RESET) => sub {
            $prev = $current = undef;
            $next = 0;
        },

        (+REWIND) => sub {
            $next = 0;
        },

        (+PREV) => sub {
            return defined $prev ? $arr->[$prev] : undef;
        },

        (+CURRENT) => sub {
            return defined $current ? $arr->[$current] : undef;
        },

        (+NEXT) => sub {
            $next    = 0 if $next == $len;
            $prev    = $current;
            $current = $next++;
            return $arr->[$current];
        },

        (+FREEZE) => sub {
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
      State::Registry
      Next::Closure
      Rewind::Closure
      Reset::Closure
      Prev::Closure
      Current::Closure
      Freeze
] );


1;

# COPYRIGHT
