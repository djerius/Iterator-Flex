package Iterator::Flex::Iterator::Reset;

# ABSTRACT: Role to add reset capability to an Iterator::Flex::Iterator

use strict;
use warnings;

our $VERSION = '0.02';

use Carp       ();
use List::Util ();

use Role::Tiny;
use Iterator::Flex::Constants;

=method reset

=method __reset__

   $iterator->reset;

Resets the iterator to its initial value.

=cut

sub reset {

    my $self = shift;

    if ( defined $self->{depends} ) {

        # first check if dependencies can reset.
        my $cant
          = List::Util::first { !$_->can( 'reset' ) } @{ $self->{depends} };
        Carp::croak( "dependency: @{[ $cant->{name} ]} is not resetable\n" )
          if $cant;

        # now reset them
        $_->reset foreach @{ $self->{depends} };
    }

    local $_ = $self;
    $self->{reset}->();
    $self->_set_state( Iterator::Flex::Constants::INACTIVE );

    return;
}
*__reset__ = \&reset;



1;
