package Iterator::Flex::Array;

use strict;
use warnings;

our $VERSION = '0.04';

use parent 'Iterator::Flex::Base';

__PACKAGE__->_add_roles(
    qw[ ExhaustedPredicate
      Rewind
      Reset
      Previous
      Current
      Serialize
      ] );

1;
