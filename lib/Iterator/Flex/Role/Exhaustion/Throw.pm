package Iterator::Flex::Role::Exhaustion::Throw;

# ABSTRACT: signal exhaustion by setting exhausted flag;

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;
use Iterator::Flex::Utils qw( :default :RegistryKeys );
use Ref::Util;

use namespace::clean;

=method signal_exhaustion

   $iterator->signal_exhaustion;

Signal that the iterator is exhausted.  This version sets the
iterator's exhausted flag and throws an exception.


=cut

sub signal_exhaustion {
    my $self = shift;
    $self->set_exhausted;

    my $exception = $REGISTRY{refaddr $self}{+GENERAL}{+EXHAUSTION}[1];

    $exception->() if Ref::Util::is_coderef( $exception );

    require Iterator::Flex::Failure;
    Iterator::Flex::Failure::Exhausted->throw;
}

requires 'set_exhausted';

1;

# COPYRIGHT
