package Iterator::Flex::Role::Rewind;

# ABSTRACT: Role to add rewind capability to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.04';

use Carp       ();
use List::Util ();

use Iterator::Flex::Base ();
use Role::Tiny;

=method rewind

=method __rewind__

   $iterator->rewind;

Resets the iterator to its initial value.

=cut

sub rewind {

    my $obj  = $_[0];
    my $self = $Iterator::Flex::Base::REGISTRY{ Scalar::Util::refaddr $obj };

    if ( defined $self->{depends} ) {

        Carp::croak( "a dependency is not rewindable\n" )
          unless $obj->_may_meth( 'rewind', $self );

        # now rewind them
        $_->rewind foreach @{ $self->{depends} };
    }

    $self->{rewind}->( $obj );
    $self->{is_exhausted} = 0;

    return;
}
*__rewind__ = \&rewind;

around may => Iterator::Flex::Base->_wrap_may( 'rewind' );

1;
