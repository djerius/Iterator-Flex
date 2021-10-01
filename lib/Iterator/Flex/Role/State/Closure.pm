package Iterator::Flex::Role::State::Closure;

# ABSTRACT: Iterator State is kept in a closure variable

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;
use Iterator::Flex::Utils qw( :default ITERATOR STATE :IterStates );

use namespace::clean;

=method set_state

  $iter->set_state( $state );

Set the iterator's state to $state

=cut

sub set_state {

    ${ $REGISTRY{ refaddr $_[0] }{ +ITERATOR }{ +STATE } } = $_[1]
      unless ( ${ $REGISTRY{ refaddr $_[0] }{ +ITERATOR }{ +STATE } }
        // +IterState_CLEAR ) == +IterState_ERROR;
}

=method set_state

  $iter->set_state( $state );

Get the iterator's state;

=cut

sub get_state {
    ${ $REGISTRY{ refaddr $_[0] }{+ITERATOR}{+STATE} };
}
1;

# COPYRIGHT
