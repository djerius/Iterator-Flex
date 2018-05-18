package Iterator::Flex::Role::Previous;

# ABSTRACT: Role to add prev method to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.09';

use Role::Tiny;

=method prev

=method __prev__

   $iterator->prev;

Returns the previous value.

=cut

sub prev {

    my $attributes = $Iterator::Flex::Base::REGISTRY{ Scalar::Util::refaddr $_[0] };

    $attributes->{prev}->( $_[0] );
}
*__prev__ = \&prev;


1;
