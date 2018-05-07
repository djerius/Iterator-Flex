package Iterator::Flex::Role::Current;

# ABSTRACT: Role to add current method to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.05';

use Role::Tiny;

=method current

=method __current__

   $iterator->current;

Returns the current value.

=cut

sub current {

    my $self = $Iterator::Flex::Base::REGISTRY{ Scalar::Util::refaddr $_[0] };

    $self->{current}->( $_[0] );
}
*__current__ = \&current;


1;
