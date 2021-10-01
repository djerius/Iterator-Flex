package Iterator::Flex::Role::State::Registry;

# ABSTRACT: Iterator State is kept in the registry

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;
use Iterator::Flex::Utils qw( :default ITERATOR ITERATOR_STATE :IterStates );

use namespace::clean;

=method set_state

  $iter->set_state( $state );

Set the iterator's state to C<$state>

=cut

sub set_state {
    $REGISTRY{ refaddr $_[0] }{+ITERATOR}{+ITERATOR_STATE} = $_[1]
      unless ( $REGISTRY{ refaddr $_[0] }{+ITERATOR}{+ITERATOR_STATE} // +IterState_CLEAR ) == +IterState_ERROR;
}

=method set_state

  $iter->set_state( $state );

Get the iterator's state;

=cut

sub get_state {
    $REGISTRY{ refaddr $_[0] }{+ITERATOR}{+ITERATOR_STATE};
}


1;

# COPYRIGHT
