package Iterator::Flex::Role::State;

# ABSTRACT: abstract interface role for State

use strict;
use warnings;

our $VERSION = '0.15';

use Role::Tiny;

requires 'set_state';

1;

# COPYRIGHT
