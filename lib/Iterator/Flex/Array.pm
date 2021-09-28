package Iterator::Flex::Array;

# ABSTRACT: Array Iterator Class

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Utils ':IterAttrs';
use Ref::Util;
use namespace::clean;

use parent 'Iterator::Flex::Base';

=method new

  $iterator = Iterator::Flex::Array->new( $array_ref );

Wrap an array in an iterator.

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

    my ( $class, $state ) = @_;

    $class->_throw( parameter => "'state' parameter must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $arr, $prev, $current, $next )
      = @{$state}{qw[ array prev current next ]};

    $class->_throw( parameter => "state 'array' parameter must be a HASH reference" )
      unless Ref::Util::is_arrayref( $arr );

    my $len = @$arr;

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
            return defined $prev ? $arr->[$prev] : undef;
        },

        CURRENT ,=> sub {
            return defined $current ? $arr->[$current] : undef;
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

            return $arr->[$current];
        },

        FREEZE ,=> sub {
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
      Exhausted::Registry
      Next::ClosedSelf
      Rewind::Closure
      Reset::Closure
      Prev::Closure
      Current::Closure
      Freeze
] );

1;

# COPYRIGHT
