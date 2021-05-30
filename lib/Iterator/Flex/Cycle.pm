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

sub new {
    my $class = shift;
    my $gpar = Ref::Util::is_hashref( $_[-1] ) ? pop : {};

    $class->_throw( parameter => "argument must be an ARRAY reference" )
      unless Ref::Util::is_arrayref( $_[0] );

    $class->SUPER::new( { array => $_[0] }, $gpar );
}

sub construct {
    my ( $class, $state ) = ( shift, shift );

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

    $class->throw( parameter => "illegal value for 'next'" )
      if $next < 0 || $next > $len;


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
      ::Exhausted::NoOp
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
