package Iterator::Flex::Cache;

# ABSTRACT: Cache Iterator Class

use strict;
use warnings;

our $VERSION = '0.12';

use parent 'Iterator::Flex::Base';
use Iterator::Flex::Utils qw( IS_EXHAUSTED );
use Iterator::Flex::Factory;
use Scalar::Util;

use namespace::clean;

=method new

  $iterator = Iterator::Flex::Cache->new( $iterable );

The iterator caches the current and previous values of C<$iterable>,
C<$iteratable> is converted into an iterator (if it is not already
one) via L<Iterator::Flex::Factory/to_iterable>).

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

    $class->construct_from_state( { depends => $_[0] } );
}


sub construct_from_state {

    my ( $class, $state ) = ( shift, shift );

    $class->throw( parameter => "state must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $src, $prev, $current ) = @{$state}{qw[ depends prev current ]};

    $src = Iterator::Flex::Factory->to_iterator( $src );

    my $self;
    my $is_exhausted;

    return {

        _self => \$self,

        IS_EXHAUSTED, => \$is_exhausted,

        reset => sub {
            $prev = $current = undef;
        },

        rewind => sub {
        },

        prev => sub {
            return $prev;
        },

        current => sub {
            return $current;
        },

        next => sub {

            return $current
              if $is_exhausted;

            $prev    = $current;
            $current = $src->();

            $current = $self->signal_exhaustion
              if $src->is_exhausted;

            return $current;
        },

        freeze => sub {
            return [ $class, { prev => $prev, current => $current } ];
        },

        _depends => $src,
    };
}

sub new_from_state {

    my $class = shift;

    my $state = shift;
    $state->{depends} = $state->{depends}[0];

    $class->new_from_attrs( $class->construct_from_state( $state ) );
}


__PACKAGE__->_add_roles( qw[
      ::Exhausted::Closure
      ::Next::ClosedSelf
      Next
      Rewind
      Reset
      Prev
      Current
      Freeze
] );


1;

# COPYRIGHT
