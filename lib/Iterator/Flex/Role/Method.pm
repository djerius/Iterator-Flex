package Iterator::Flex::Role::Method;

use strict;
use warnings;

our $VERSION = '0.10';

use Role::Tiny;

use Package::Variant importing => qw[ Role::Tiny ];
use Iterator::Flex::Failure 'RoleExists';

sub make_variant_package_name {
  my ($class, $package ) = @_;

  $package = "Iterator::Flex::Role::Method::$package";

  Iterator::Flex::Failure::RoleExists->throw
     if Role::Tiny->is_role( $package );

  return $package;
}

sub make_variant {
  my ($class, $target_package, $package, %arg) = @_;
  my $name = $arg{name};
  install ${name} => sub {

      my $attributes = $Iterator::Flex::Base::REGISTRY{ Scalar::Util::refaddr $_[0] };
      return $attributes->{methods}{$name}->( @_ );
  };
}

1;

__END__

=for Pod::Coverage
  make_variant_package_name
  make_variant



