package Iterator::Flex::Cache;

# ABSTRACT: Cache Iterator Class

use strict;
use warnings;

our $VERSION = '0.12';

use parent 'Iterator::Flex::Base';
use Iterator::Flex::Factory;
use Scalar::Util;

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

    unless ( Ref::Util::is_hashref( $state ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "state must be a HASH reference" );
    }

    my ( $src, $prev, $current ) = @{$state}{qw[ depends prev current ]};

    $src = Iterator::Flex::Factory->to_iterator( $src );

    my $self;

    return {

        _self => \$self,

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

            return undef
              if $self->is_exhausted;

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

        exhausted => 'predicate',
    };
}

sub new_from_state {

    my $class = shift;

    my $state = shift;
    $state->{depends} = $state->{depends}[0];

    $class->new_from_attrs( $class->construct_from_state( $state ) );
}


__PACKAGE__->_add_roles( qw[
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
