package Iterator::Flex::Role::Next::Closure;

# ABSTRACT: Construct a next() method for iterators without closed over $self

use strict;
use warnings;

our $VERSION = '0.15';

use Iterator::Flex::Utils 'NEXT';
use Scalar::Util;
use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

=method next

=method __next__

   $iterator->next;

Wrapper for iterator next callback optimized for the case where
iterator exhaustion is handled by the iterator.  Typically this means
the iterator closure calls C<< $self->signal_exhaustion >>, which is added
by a specific C<Iterator::Flex::Role::Exhaustion> role.

=cut

sub _construct_next ( $class, $ipar, $ ) {

    # ensure we don't hold any strong references in the subroutine
    my $sub = $ipar->{ +NEXT } // $class->_throw( parameter => "Missing 'next' parameter" );
    Scalar::Util::weaken $ipar->{ +NEXT };
    return $sub;
}

sub next ( $self ) { &{$self}() }
*__next__ = \&next;

1;

# COPYRIGHT
