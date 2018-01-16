package Iterator::Flex::Iterator::Rewind;

# ABSTRACT: Role to add rewind capability to an Iterator::Flex::Iterator

use strict;
use warnings;

our $VERSION = '0.02';

use Carp       ();
use List::Util ();

use Role::Tiny;
use Iterator::Flex::Constants;

=method rewind

=method __rewind__

   $iterator->rewind;

Resets the iterator to its initial value.

=cut

sub rewind {

    my $self = shift;

    if ( defined $self->{depends} ) {

        # first check if dependencies can rewind.
        my $cant
          = List::Util::first { !$_->can( 'rewind' ) } @{ $self->{depends} };
        Carp::croak( "dependency: @{[ $cant->{name} ]} is not rewindable\n" )
          if $cant;

        # now rewind them
        $_->rewind foreach @{ $self->{depends} };
    }

    local $_ = $self;
    $self->{rewind}->();
    $self->_set_state( Iterator::Flex::Constants::INACTIVE );

    return;
}
*__rewind__ = \&rewind;



1;
