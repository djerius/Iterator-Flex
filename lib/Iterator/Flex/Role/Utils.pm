package Iterator::Flex::Role::Utils;

# ABSTRACT: Internal utilities

use strict;
use warnings;

use Role::Tiny;

our $VERSION = '0.10';

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
    my ( $obj, $meth ) = @{_}[-2,-1];

    my $sub;
    foreach ( "__${meth}__", $meth ) {
        last if defined( $sub = $obj->can( $_ ) );
    }

    return $sub;
}

1;

# COPYRIGHT
