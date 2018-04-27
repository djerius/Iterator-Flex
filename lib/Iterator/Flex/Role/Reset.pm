package Iterator::Flex::Role::Reset;

# ABSTRACT: Role to add reset capability to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.04';

use Carp       ();
use List::Util ();

use Iterator::Flex::Base ();
use Role::Tiny;

=method reset

=method __reset__

   $iterator->reset;

Resets the iterator to its initial value.

=cut

sub reset {

    my $obj = $_[0];

    my $self = $Iterator::Flex::Base::REGISTRY{ Scalar::Util::refaddr $obj };

    if ( defined $self->{depends} ) {

        # first check if dependencies can reset.
        my $cant
          = List::Util::first { !$_->can( 'reset' ) } @{ $self->{depends} };
        Carp::croak( "dependency: @{[ $cant->{name} ]} is not resetable\n" )
          if $cant;

        # now reset them
        $_->reset foreach @{ $self->{depends} };
    }

    $self->{reset}->( $obj );
    $self->{is_exhausted} = 0;

    return;
}
*__reset__ = \&reset;

around may => Iterator::Flex::Base->_wrap_may( 'reset' );

1;
