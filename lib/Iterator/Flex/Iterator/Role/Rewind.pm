package Iterator::Flex::Iterator::Role::Rewind;

# ABSTRACT: Role to add rewind capability to an Iterator::Flex::Iterator

use strict;
use warnings;

our $VERSION = '0.04';

use Carp       ();
use List::Util ();

use Iterator::Flex;
use Role::Tiny;

=method rewind

=method __rewind__

   $iterator->rewind;

Resets the iterator to its initial value.

=cut

sub rewind {

    my $obj = $_[0];
    my $self = $Iterator::Flex::Iterator::REGISTRY{ Scalar::Util::refaddr $obj };

    if ( defined $self->{depends} ) {

        # first check if dependencies can rewind.
        my $cant
          = List::Util::first { !$_->can( 'rewind' ) } @{ $self->{depends} };
        Carp::croak( "dependency: @{[ $cant->{name} ]} is not rewindable\n" )
          if $cant;

        # now rewind them
        $_->rewind foreach @{ $self->{depends} };
    }

    $self->{rewind}->( $obj );
    $self->{is_exhausted} = 0;

    return;
}
*__rewind__ = \&rewind;



1;
