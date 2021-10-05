package Iterator::Flex::Array;

# ABSTRACT: Array Iterator Class

use strict;
use warnings;

our $VERSION = '0.13';

use Iterator::Flex::Utils ':IterAttrs';
use Ref::Util;
use namespace::clean;
use experimental 'signatures';

use parent 'Iterator::Flex::Base';

=method new

  $iterator = Iterator::Flex::Array->new( $array_ref, ?\%pars );

Wrap an array in an iterator.

The optional C<%pars> hash may contain standard I<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters>.

The returned iterator supports the following capabilities:

=over

=item current

=item next

=item prev

=item rewind

=item reset

=item freeze

=back

=cut

sub new ( $class, $array, $pars={} ) {
    $class->_throw( parameter => "argument must be an ARRAY reference" )
      unless Ref::Util::is_arrayref( $array );

    $class->SUPER::new( { array => $array }, $pars );
}


sub construct ( $class, $state ) {

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

        (+_SELF) => \$self,

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
            if ( $next == $len ) {
                # if first time through, set prev
                $prev = $current
                  if ! $self->is_exhausted;
                return $current = $self->signal_exhaustion;
            }
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
      Next::ClosedSelf
      Rewind::Closure
      Reset::Closure
      Prev::Closure
      Current::Closure
      Freeze
] );

1;

# COPYRIGHT
