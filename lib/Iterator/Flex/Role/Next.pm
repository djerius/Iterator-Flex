package Iterator::Flex::Role::Next;

# ABSTRACT: provide next and __next__ from blessed coderef

use strict;
use warnings;

our $VERSION = '0.11';

use Scalar::Util;
use Role::Tiny;

=method next

=method __next__

   $iterator->next;

=cut


sub next { &{$_[0]} }

*__next__ = \&next;

1;

# COPYRIGHT
