package Iterator::Flex::Role::Error::Throw;

# ABSTRACT: signal error by throwing

use strict;
use warnings;

our $VERSION = '0.15';

use Iterator::Flex::Utils qw( :default :RegistryKeys );
use Ref::Util;

use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

=method signal_error

   $iterator->signal_error;

Signal that an error occurred.  This version sets the
iterator's error flag and throws an exception.


=cut

sub signal_error ( $self ) {
    $self->set_error;
    my $exception = $REGISTRY{ refaddr $self}{ +GENERAL }{ +ERROR }[1];

    $exception->() if Ref::Util::is_coderef( $exception );

    require Iterator::Flex::Failure;
    Iterator::Flex::Failure::Error->throw;
}


1;

# COPYRIGHT
