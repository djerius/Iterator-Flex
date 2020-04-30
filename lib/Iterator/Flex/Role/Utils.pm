package Iterator::Flex::Role::Utils;

# ABSTRACT: Internal utilities

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;

sub _load_module {

    my $class     = shift;
    my $module    = pop;
    my @hierarchy = @_;

    # if the module has embedded ::'s, we take that to mean it's the
    # complete module name, and don't try and load it.  This is a kludge
    # to deal with modules dynamically generated by Iterator::Flex::Method
    return $module if $module =~ /::/;

    for my $namespace ( $class->_namespaces ) {
        my $module = _module_name( $namespace, @hierarchy, $module );
        return $module if eval { Module::Runtime::require_module( $module ) };
    }

    $class->_croak(
        "unable to find a module for ",
        join( "::", @hierarchy, $module ),
        " in @{[ join( ', ', $class->_namespaces ) ]}"
    );
}

sub _load_role {
    my ( $class, $role ) = @_;

    for my $namespace ( $class->_namespaces ) {
        my $module = "${namespace}::Role::${role}";
        return $module if eval { Module::Runtime::require_module( $module ) };
    }

    $class->_croak(
        "unable to find a module for role '$role' in @{[ join( ',', $class->_namespaces ) ]}"
    );
}

sub _module_name {

    my $class     = shift;
    my $module    = pop;
    my @hierarchy = @_;

    return $module if $module =~ /::/;

    $class = 'Iterator::Flex' if $class =~ /^Iterator::Flex(?:::.*|$)/;

    return join( '::', $class, @hierarchy, $module );
}

sub _can_meth {

    # just in case the first argument is an object or class
    my ( $obj, $meth ) = @{_}[ -2, -1 ];

    my $sub;
    foreach ( "__${meth}__", $meth ) {
        last if defined( $sub = $obj->can( $_ ) );
    }

    return $sub;
}

1;

# COPYRIGHT
