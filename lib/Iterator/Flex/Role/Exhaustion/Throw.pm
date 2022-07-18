package Iterator::Flex::Role::Exhaustion::Throw;

# ABSTRACT: signal exhaustion by setting exhausted flag;

use strict;
use warnings;

our $VERSION = '0.16';

use Ref::Util;
use Iterator::Flex::Utils qw( :default :RegistryKeys );

use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

=method signal_exhaustion

   $iterator->signal_exhaustion;

Signal that the iterator is exhausted.  This version sets the
iterator's exhausted flag and throws an exception.


=cut

sub signal_exhaustion ( $self, @ ) {
    $self->set_exhausted;

    my $exception = $REGISTRY{ refaddr $self}{ +GENERAL }{ +EXHAUSTION }[1];

    $exception->() if Ref::Util::is_coderef( $exception );

    require Iterator::Flex::Failure;
    Iterator::Flex::Failure::Exhausted->throw;
}


1;

# COPYRIGHT
