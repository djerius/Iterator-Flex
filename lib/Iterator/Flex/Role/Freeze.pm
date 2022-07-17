package Iterator::Flex::Role::Freeze;

# ABSTRACT: Role to add serialization capability to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.15';

use List::Util;

use Iterator::Flex::Utils qw( :default ITERATOR :IterAttrs :RegistryKeys );
use Iterator::Flex::Base;
use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

=method freeze

  $freeze = $iter->freeze;

Returns a recipe to freeze an iterator and its dependencies.  See
L<Iterator::Flex/"Serialization of Iterators"> for more information.

=cut

sub freeze ( $obj ) {

    my $ipar = $REGISTRY{ refaddr $obj }{ +ITERATOR };

    my @freeze;

    if ( defined $ipar->{ +_DEPENDS } ) {

        # first check if dependencies can freeze.
        my $cant = List::Util::first { !$_->can( 'freeze' ) }
        @{ $ipar->{ +_DEPENDS } };
        $obj->_throw( parameter => "dependency: @{[ $cant->_name ]} is not serializeable" )
          if $cant;

        # now freeze them
        @freeze = map $_->freeze, @{ $ipar->{ +_DEPENDS } };
    }

    push @freeze, $ipar->{ +FREEZE }->( $obj ), $obj->is_exhausted;

    return \@freeze;
}

requires 'is_exhausted';

1;

# COPYRIGHT
