package Iterator::Flex::Array;

# ABSTRACT: Array Iterator Class

use strict;
use warnings;

our $VERSION = '0.11';

use parent 'Iterator::Flex::Base';
use Ref::Util;

=for stopwords attr

=method attr

  $iterator = Iterator::Flex::Array->attr( $array_ref );

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

sub construct {
    my $class = shift;

    $class->_croak( "argument must be an ARRAY reference" )
      unless Ref::Util::is_arrayref( $_[0] );

    $class->construct_from_state( { array => $_[0] } );
}

sub construct_from_state {

    my ( $class, $state ) = @_;

    $class->_croak( "state must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $arr, $prev, $current, $next )
      = @{$state}{qw[ array prev current next ]};

    $class->_croak( "state 'array' argument must be an ARRAY reference" )
      unless Ref::Util::is_arrayref( $arr );

    my $len = @$arr;

    $next = 0 unless defined $next;

    $class->_croak( "illegal value for state 'prev' argument" )
      if defined $prev && ( $prev < 0 || $prev >= $len );

    $class->_croak( "illegal value for state 'current' argument" )
      if defined $current && ( $current < 0 || $current >= $len );

    $class->_croak( "illegal value for state 'next' argument" )
      if $next < 0 || $next > $len;

    my $self;

    return {

        set_self => sub {
            $self = shift;
            Scalar::Util::weaken( $self );
        },

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
      Exhausted
      Next::ClosedSelf
      Next
      Rewind
      Reset
      Prev
      Current
      Freeze
] );

1;

# COPYRIGHT
