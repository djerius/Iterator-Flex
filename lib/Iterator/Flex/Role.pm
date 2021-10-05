package Iterator::Flex::Role;

# ABSTRACT: Iterator Methods to add Iterator::Flex Iterator modifiers

use strict;
use warnings;

our $VERSION = '0.13';

use Role::Tiny;
use experimental 'signatures';

# avoid compile time dependency loop madness
require Iterator::Flex;

# the \&{...} nonsense below is to keep the prototype checker happy

=method icache

  $new_iter = $iter->icache( sub { ... } );

Return a new iterator caching the original iterator via L<Iterator::Flex/icache>.

=cut

sub icache ( $iter, $code ) { Iterator::Flex::icache( \&{ $code }, $iter ) }

=method igrep

  $new_iter = $iter->igrep( sub { ... } );

Return a new iterator modifying the original iterator via L<Iterator::Flex/igrep>.

=cut

sub igrep ( $iter, $code ) { Iterator::Flex::igrep( \&{ $code }, $iter ) }

=method imap

  $new_iter = $iter->imap( sub { ... } );

Return a new iterator modifying the original iterator via L<Iterator::Flex/ifreeze>.

=cut

sub imap ( $iter, $code ) { Iterator::Flex::imap( \&{ $code }, $iter ) }

=method ifreeze

  $new_iter = $iter->ifreeze( sub { ... } );

Return a new iterator modifying the original iterator via L<Iterator::Flex/ifreeze>.

=cut

sub ifreeze ( $iter, $code ) { Iterator::Flex::ifreeze( \&{ $code }, $iter ) }

1;

# COPYRIGHT
