package Iterator::Flex::Utils;

# ABSTRACT: Internal utilities

use strict;
use warnings;

our $VERSION = '0.11';

use Scalar::Util qw( refaddr weaken );

use Exporter 'import';

our %REGISTRY;

our %NativeExhaustionActions;
our %RequestedExhaustionActions;

BEGIN {
    %NativeExhaustionActions = (
	THROWS_ON_EXHAUSTION  => 'throws_on_exhaustion',
	RETURNS_ON_EXHAUSTION => 'returns_on_exhaustion',
    );
    %RequestedExhaustionActions = (
	ON_EXHAUSTION_THROW  => 'on_exhaustion_throw',
	ON_EXHAUSTION_RETURN => 'on_exhaustion_return'
    );
}

use constant \%NativeExhaustionActions;
use constant \%RequestedExhaustionActions;

our @NativeExhaustionActions    = values %NativeExhaustionActions;
our @RequestedExhaustionActions = values %RequestedExhaustionActions;

our %EXPORT_TAGS = (
    NativeExhaustionActions =>
      [ qw( @NativeExhaustionActions ), keys %NativeExhaustionActions, ],
    RequestedExhaustionActions =>
      [ qw( @RequestedExhaustionActions ), keys %RequestedExhaustionActions, ],
    default => [ qw( %REGISTRY refaddr ) ]
);

our @EXPORT = @{ $EXPORT_TAGS{default} };

our @EXPORT_OK = ( qw(
      create_class_with_roles
      _safe_wrap_next
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

sub _safe_wrap_next {

    if ( exists $REGISTRY{ refaddr $_[0] } ) {
        my $sub = $_[0];
        my $rsub = sub { goto &$sub; };
        weaken $sub;
        return $rsub;
    }
    else {
        return $_[0];
    }

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
