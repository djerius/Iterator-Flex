package Iterator::Flex::Role::Error::Throw;

# ABSTRACT: signal error by throwing

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;
use Iterator::Flex::Utils qw( :default :RegistryKeys );
use Ref::Util;

use namespace::clean;

=method signal_error

   $iterator->signal_error;

Signal that an error ocurred.  This version sets the
iterator's error flag and throws an exception.


=cut

sub signal_error {
    my $self = shift;

    $self->set_error;
    my $exception = $REGISTRY{refaddr $self}{+GENERAL}{+ERROR}[1];

    $exception->() if Ref::Util::is_coderef( $exception );

    require Iterator::Flex::Failure;
    Iterator::Flex::Failure::Error->throw;
}


1;

# COPYRIGHT
