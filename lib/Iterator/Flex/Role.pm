package Iterator::Flex::Role;

# ABSTRACT: Iterator Methods to add Iterator::Flex Iterator modifiers

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;

# avoid compile time dependency loop madness
require Iterator::Flex;

# the \&{...} nonsense below is to keep the prototype checker happy

=method icache

  $new_iter = $iter->icache( sub { ... } );

Return a new iterator caching the original iterator via L<Iterator::Flex/icache>.

=cut

sub icache { Iterator::Flex::icache( \&{ $_[1] }, $_[0] ) }

=method igrep

  $new_iter = $iter->igrep( sub { ... } );

Return a new iterator modifying the original iterator via L<Iterator::Flex/igrep>.

=cut

sub igrep { Iterator::Flex::igrep( \&{ $_[1] }, $_[0] ) }

=method imap

  $new_iter = $iter->imap( sub { ... } );

Return a new iterator modifying the original iterator via L<Iterator::Flex/ifreeze>.

=cut

sub imap { Iterator::Flex::imap( \&{ $_[1] }, $_[0] ) }

=method ifreeze

  $new_iter = $iter->ifreeze( sub { ... } );

Return a new iterator modifying the original iterator via L<Iterator::Flex/ifreeze>.

=cut

sub ifreeze { Iterator::Flex::ifreeze( \&{ $_[1] }, $_[0] ) }

1;

# COPYRIGHT
