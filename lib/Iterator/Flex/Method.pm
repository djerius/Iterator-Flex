package Iterator::Flex::Method;

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.12';

# Package::Variant based modules generate constructor functions
# dynamically when those modules are imported.  However, loading the
# module via require() then calling its import method must be done
# only once, otherwise Perl will emit multiply defined errors for the
# constructor functions.

# By layering the Package::Variant based module in an inner package
# and calling its import here, the constructor function, Maker(), is
# generated just once, as Iterator::Flex::Method::Maker, and is
# available to any caller by it's fully qualified name.

Iterator::Flex::Method::Maker->import;

package Iterator::Flex::Method::Maker {

    use Iterator::Flex::Utils qw( :default ITERATOR METHODS );
    use Package::Variant importing => qw[ Role::Tiny ];
    use Module::Runtime;

    sub make_variant_package_name ( $class, $package, % ) {

        $package = "Iterator::Flex::Role::Method::$package";

        if ( Role::Tiny->is_role( $package ) ) {
            require Iterator::Flex::Failure;
            Iterator::Flex::Failure::RoleExists->throw(
                { payload => $package } );
        }

        $INC{ Module::Runtime::module_notional_filename( $package ) } = undef;
        return $package;
    }

    sub make_variant ( $class, $target_package, $package, %arg ) {
        my $name = $arg{name};
        install $name => sub {
            return $REGISTRY{ refaddr $_[0] }{ +ITERATOR }{ +METHODS }{$name}
              ->( @_ );
        };
    }
}

1;

# COPYRIGHT

__END__

=for Pod::Coverage
  make_variant_package_name
  make_variant
