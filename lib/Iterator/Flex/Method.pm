package Iterator::Flex::Method;

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Utils;
use Package::Variant importing => qw[ Role::Tiny ];
use Module::Runtime;

sub make_variant_package_name {
    my ( $class, $package ) = @_;

    $package = "Iterator::Flex::Role::Method::$package";

    if ( Role::Tiny->is_role( $package ) ) {
        use Iterator::Flex::Failure;
        Iterator::Flex::Failure::RoleExists->throw( { payload => $package } );
    }

    $INC{Module::Runtime::module_notional_filename( $package )} = undef;
    return $package;
}

sub make_variant {
    my ( $class, $target_package, $package, %arg ) = @_;
    my $name = $arg{name};
    install $name => sub {
        return $REGISTRY{ refaddr $_[0] }{methods}{$name}->( @_ );
    };
}

1;

# COPYRIGHT

__END__

=for Pod::Coverage
  make_variant_package_name
  make_variant
