package Iterator::Flex::Role::State::Closure;

# ABSTRACT: Iterator State is kept in a closure variable

use strict;
use warnings;

our $VERSION = '0.13';

use Iterator::Flex::Utils qw( :default ITERATOR STATE :IterStates );

use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

=method set_state

  $iter->set_state( $state );

Set the iterator's state to $state

=cut

sub set_state ($self, $state ) {

    ${ $REGISTRY{ refaddr $self }{ +ITERATOR }{ +STATE } } = $state
      unless ( ${ $REGISTRY{ refaddr $self }{ +ITERATOR }{ +STATE } }
        // +IterState_CLEAR ) == +IterState_ERROR;
}

=method set_state

  $iter->set_state( $state );

Get the iterator's state;

=cut

sub get_state ($self) {
    ${ $REGISTRY{ refaddr $self }{+ITERATOR}{+STATE} };
}
1;

# COPYRIGHT
