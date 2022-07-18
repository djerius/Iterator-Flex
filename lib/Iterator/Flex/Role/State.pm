package Iterator::Flex::Role::State;

# ABSTRACT: abstract interface role for State

use strict;
use warnings;

our $VERSION = '0.16';

use Role::Tiny;

requires 'set_state';

1;

# COPYRIGHT
