package Iterator::Flex::Role::Next::NoSelf;

# ABSTRACT: Construct a next() method for iterators which handle exhaustion

use strict;
use warnings;

our $VERSION = '0.11';

use Scalar::Util;
use Role::Tiny;

=method next

=method __next__

   $iterator->next;

Wrapper for iterator next callback optimized for the case where
iterator exhaustion is handled by the iterator.  Typically this means
the iterator closure calls C<$self->signal_exhaustion>, which is added
by a specific L<Iterator::Flex::Role::Exhaustion> role.

=cut

sub _construct_next {

    # my $class = shift;
    shift;
    my $attributes = shift;

    # ensure we don't hold any strong references in the subroutine
    my $sub = $attributes->{next};
    Scalar::Util::weaken $attributes->{next};
    return $sub;
}

1;

# COPYRIGHT
