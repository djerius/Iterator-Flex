package Iterator::Flex::Utils;

# ABSTRACT: Internal utilities

use strict;
use warnings;

our $VERSION = '0.10';

use Ref::Util qw[ is_arrayref ];
use Exporter 'import';

use Role::Tiny::With;

with 'Iterator::Flex::Role::Utils';

our @EXPORT_OK = qw(
  create_class_with_roles
  _can_meth
);


sub create_class_with_roles {

    my $base = shift;

    my $class = Role::Tiny->create_class_with_roles( $base,
        map { $base->_module_name( 'Role' => ref $_ ? @{$_} : $_ ) } @_ );

    _croak(
        "class '$class' does not provide the required _construct_next method\n" )
      unless $class->can( '_construct_next' );

    return $class;
}

1;

# COPYRIGHT
