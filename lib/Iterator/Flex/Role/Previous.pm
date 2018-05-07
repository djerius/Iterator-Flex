package Iterator::Flex::Role::Previous;

# ABSTRACT: Role to add prev method to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.05';

use Role::Tiny;

=method prev

=method __prev__

   $iterator->prev;

Returns the previous value.

=cut

sub prev {

    my $self = $Iterator::Flex::Base::REGISTRY{ Scalar::Util::refaddr $_[0] };

    $self->{prev}->( $_[0] );
}
*__prev__ = \&prev;


1;
