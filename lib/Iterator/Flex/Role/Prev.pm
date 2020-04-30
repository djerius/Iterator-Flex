package Iterator::Flex::Role::Prev;

# ABSTRACT: Role to add prev method to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Utils;
use Role::Tiny;

use namespace::clean;

=method prev

=method __prev__

   $iterator->prev;

Returns the previous value.

=cut

sub prev {

    my $attributes = $REGISTRY{ refaddr $_[0] };

    $attributes->{prev}->( $_[0] );
}
*__prev__ = \&prev;

1;

# COPYRIGHT
