package Iterator::Flex::Utils;

# ABSTRACT: Internal utilities

use strict;
use warnings;

our $VERSION = '0.06';

use Iterator::Flex::Role::Method;

=sub create_method

A horrible kludge to avoid adding a C<Method> to
L<Iterator::Flex::Base>.  L<Package::Variant> based classes export a generated factory into
the calling package, which pollutes a class' namespace

=cut

*create_method = \&Method;

1;



