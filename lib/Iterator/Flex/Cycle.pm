package Iterator::Flex::Cycle;

# ABSTRACT: Array Cycle Iterator Class

use strict;
use warnings;

our $VERSION = '0.10';

use Carp ();
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

    my $class  = shift;

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

        next =>sub {
            $next    = 0 if $next == $len;
            $prev    = $current;
            $current = $next++;
            return $arr->[$current];
        },

        freeze => sub {
            return [
                $class, '_construct',
                [ $class, $arr, $prev, $current, $next ] ];
        },
    );
}


__PACKAGE__->_add_roles(
    qw[ ExhaustedUndef
      Rewind
      Reset
      Previous
      Current
      Serialize
      ] );


1;
