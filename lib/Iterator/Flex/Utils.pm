package Iterator::Flex::Utils;

# ABSTRACT: Internal utilities

use 5.28.1;

use strict;
use warnings;

use experimental 'signatures';

our $VERSION = '0.12';

use Scalar::Util qw( refaddr );

use Exporter 'import';

our %REGISTRY;

our %ExhaustionActions;
our %RegistryKeys;
our %IterAttrs;
our %Methods;

BEGIN {
    %ExhaustionActions = ( map { $_ => lc $_ } qw[ THROW RETURN PASSTHROUGH ] );

    %RegistryKeys
      = ( map { $_ => lc $_ }
          qw[ INPUT_EXHAUSTION EXHAUSTION IS_EXHAUSTED ITERATOR GENERAL METHODS ]
      );

    %IterAttrs
      = ( map { $_ => lc $_ }
          qw[ _SELF _DEPENDS _ROLES _NAME
              NEXT PREV CURRENT REWIND RESET FREEZE METHODS ]
      );

    %Methods = ( map { $_ => lc $_ } qw[ IS_EXHAUSTED SET_EXHAUSTED  ] );

}

use constant \%ExhaustionActions;
use constant \%RegistryKeys;
use constant \%IterAttrs;
use constant \%Methods;

our %EXPORT_TAGS = (
    ExhaustionActions => [ keys %ExhaustionActions, ],
    RegistryKeys      => [ keys %RegistryKeys ],
    IterAttrs         => [ keys %IterAttrs ],
    Methods           => [ keys %Methods ],
    default           => [qw( %REGISTRY refaddr )],
);

our @EXPORT = @{ $EXPORT_TAGS{default} };

our @EXPORT_OK = ( qw(
      create_class_with_roles
      ),
    map { @{$_} } values %EXPORT_TAGS,
);


use Role::Tiny::With;
with 'Iterator::Flex::Role::Utils';

sub create_class_with_roles ( $base, @roles ) {

    my $class = Role::Tiny->create_class_with_roles( $base,
        map { $base->_load_role( $_ ) } @roles );

    unless ( $class->can( '_construct_next' ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::class->throw(
            "Constructed class '$class' does not provide the required _construct_next method\n"
        );
    }

    return $class;
}

1;

# COPYRIGHT
