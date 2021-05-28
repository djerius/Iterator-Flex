package Iterator::Flex::Role::Exhausted::NoOp;

# ABSTRACT: Role for iterator which handles set_exhausted and is_exhausted predicate.

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;

use namespace::clean;

=method set_exhausted

  $iter->set_exhausted;

Set the iterator's state to exhausted

=cut

sub set_exhausted {}

sub _reset_exhausted {}


=method is_exhausted

  $bool = $iter->is_exhausted;

Always returns false.

=cut

sub is_exhausted { 0 }


1;

# COPYRIGHT
