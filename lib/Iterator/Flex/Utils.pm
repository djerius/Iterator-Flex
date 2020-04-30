package Iterator::Flex::Utils;

# ABSTRACT: Internal utilities

use strict;
use warnings;

our $VERSION = '0.11';

use Scalar::Util qw( refaddr );

use Exporter 'import';

our %REGISTRY;

our %ImportedExhaustionActions;
our %ExhaustionActions;

BEGIN {
    %ImportedExhaustionActions = (
        THROWS_ON_EXHAUSTION  => 'throws_on_exhaustion',
        RETURNS_ON_EXHAUSTION => 'returns_on_exhaustion',
    );
    %ExhaustionActions = (
        ON_EXHAUSTION_THROW       => 'on_exhaustion_throw',
        ON_EXHAUSTION_RETURN      => 'on_exhaustion_return',
        ON_EXHAUSTION_PASSTHROUGH => 'on_exhaustion_passthrough',
    );
}

use constant \%ImportedExhaustionActions;
use constant \%ExhaustionActions;

our @ImportedExhaustionActions    = values %ImportedExhaustionActions;
our @ExhaustionActions = values %ExhaustionActions;

our %EXPORT_TAGS = (
    ImportedExhaustionActions =>
      [ qw( @ImportedExhaustionActions ), keys %ImportedExhaustionActions, ],
    ExhaustionActions =>
      [ qw( @ExhaustionActions ), keys %ExhaustionActions, ],
    default => [qw( %REGISTRY refaddr )],
);

our @EXPORT = @{ $EXPORT_TAGS{default} };

our @EXPORT_OK = ( qw(
      create_class_with_roles
      _can_meth
      _croak
      ),
    map { @{$_} } values %EXPORT_TAGS,
);

use Ref::Util qw[ is_arrayref ];


use Role::Tiny::With;
with 'Iterator::Flex::Role::Utils';

sub _croak {
    require Carp;
    Carp::croak( @_ );
}

sub create_class_with_roles {

    my $base = shift;

    my $class = Role::Tiny->create_class_with_roles( $base,
        map { $base->_load_module( 'Role' => ref $_ ? @{$_} : $_ ) } @_ );

    _croak(
        "class '$class' does not provide the required _construct_next method\n"
    ) unless $class->can( '_construct_next' );

    return $class;
}

1;

# COPYRIGHT
