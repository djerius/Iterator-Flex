package Iterator::Flex::Array;

# ABSTRACT: Array Iterator Class

use strict;
use warnings;

our $VERSION = '0.04';

use Carp ();
use parent 'Iterator::Flex::Base';
use Ref::Util;

## no critic ( ProhibitExplicitReturnUndef )

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
    $class->_construct( $_[0], undef, undef, undef );
}

sub _construct {

    my $class = shift;
    my ( $arr, $prev, $current, $next ) = @_;

    Carp::croak "$class: argument must be an ARRAY reference"
      unless Ref::Util::is_arrayref( $arr );

    my $len = @$arr;

    $next = 0 unless defined $next;

    return $class->_ITERATOR_BASE->construct(

        class => $class,

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
                if ( !$_[0]->is_exhausted ) {
                    $prev    = $current;
                    $current = undef;
                    $_[0]->set_exhausted;
                }
                return undef;
            }
            $prev    = $current;
            $current = $next++;
            return $arr->[$current];
        },

        freeze => sub {
            return [ $class, '_construct', [ $class, $arr, $prev, $current, $next ] ];
        },

        exhausted => 'predicate',
    );
}


__PACKAGE__->_add_roles(
    qw[ ExhaustedPredicate
      Rewind
      Reset
      Previous
      Current
      Serialize
      ] );


1;
