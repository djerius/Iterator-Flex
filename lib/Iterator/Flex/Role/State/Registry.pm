package Iterator::Flex::Role::State::Registry;

# ABSTRACT: Iterator State is kept in the registry

use strict;
use warnings;

our $VERSION = '0.16';

use Iterator::Flex::Utils qw( :default ITERATOR STATE :IterStates );

use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

=method set_state

  $iter->set_state( $state );

Set the iterator's state to C<$state>

=cut

sub set_state ( $self, $state ) {
    $REGISTRY{ refaddr $self }{ +ITERATOR }{ +STATE } = $state
      unless ( $REGISTRY{ refaddr $self }{ +ITERATOR }{ +STATE } // + IterState_CLEAR )
      == +IterState_ERROR;
}

=method set_state

  $iter->set_state( $state );

Get the iterator's state;

=cut

sub get_state ( $self ) {
    $REGISTRY{ refaddr $self }{ +ITERATOR }{ +STATE };
}

with 'Iterator::Flex::Role::State';

1;

# COPYRIGHT
