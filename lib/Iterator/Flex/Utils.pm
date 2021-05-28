package Iterator::Flex::Utils;

# ABSTRACT: Internal utilities

use 5.28.1;

use strict;
use warnings;

use experimental 'signatures';

our $VERSION = '0.12';

use Scalar::Util qw( refaddr );

use Exporter 'import';

use Iterator::Flex::Failure;

our %REGISTRY;

our %ExhaustionActions;
our %RegistryKeys;

BEGIN {
    %ExhaustionActions = ( map { $_ => lc $_ }
          qw[ THROW RETURN PASSTHROUGH ] );
    %RegistryKeys = (
        map { $_ => lc $_ }
          qw[ IMPORTED_EXHAUSTION EXHAUSTION IS_EXHAUSTED ITERATOR GENERAL METHODS ] );
}

use constant \%ExhaustionActions;
use constant \%RegistryKeys;

our %EXPORT_TAGS = (
    ExhaustionActions         => [ keys %ExhaustionActions, ],
    RegistryKeys              => [ keys %RegistryKeys ],
    default                   => [qw( %REGISTRY refaddr )],
);

our @EXPORT = @{ $EXPORT_TAGS{default} };

our @EXPORT_OK = ( qw(
      create_class_with_roles
      _can_meth
      ),
    map { @{$_} } values %EXPORT_TAGS,
);

use Ref::Util qw[ is_arrayref ];


use Role::Tiny::With;
with 'Iterator::Flex::Role::Utils';

sub create_class_with_roles ( $base, @roles ) {

    my $class = Role::Tiny->create_class_with_roles( $base,
        map { $base->_load_module( 'Role' => ref $_ ? @{$_} : $_ ) } @roles );

    Iterator::Flex::Failure::class->throw(
        "Constructed class '$class' does not provide the required _construct_next method\n"
    ) unless $class->can( '_construct_next' );

    return $class;
}

1;

# COPYRIGHT
