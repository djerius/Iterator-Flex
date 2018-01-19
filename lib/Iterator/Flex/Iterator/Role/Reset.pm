package Iterator::Flex::Iterator::Role::Reset;

# ABSTRACT: Role to add reset capability to an Iterator::Flex::Iterator

use strict;
use warnings;

our $VERSION = '0.04';

use Carp       ();
use List::Util ();

use Role::Tiny;

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
    $self->{is_exhausted} = 0;

    return;
}
*__reset__ = \&reset;



1;
