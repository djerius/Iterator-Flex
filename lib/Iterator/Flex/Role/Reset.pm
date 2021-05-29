package Iterator::Flex::Role::Reset;

# ABSTRACT: Role to add reset capability to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.12';

use Scalar::Util;
use List::Util;

use Iterator::Flex::Base ();
use Iterator::Flex::Utils qw( :default ITERATOR );
use Role::Tiny;

use namespace::clean;

=method reset

=method __reset__

   $iterator->reset;

Resets the iterator to its initial value.

=cut

sub reset {

    my $obj = $_[0];

    my $ipar = $REGISTRY{ refaddr $obj }{ +ITERATOR };

    if ( defined $ipar->{_depends} ) {

        # first check if dependencies can reset.
        my $cant
          = List::Util::first { !$_->can( 'reset' ) } @{ $ipar->{_depends} };
        $obj->_throw( parameter =>
              "dependency: @{[ $cant->{_name} ]} does not have a 'reset' method"
        ) if $cant;

        # now reset them
        $_->reset foreach @{ $ipar->{_depends} };
    }

    $ipar->{reset}->( $obj );
    $obj->_reset_exhausted;

    return;
}
*__reset__ = \&reset;

around may => Iterator::Flex::Base->_wrap_may( 'reset' );

requires '_reset_exhausted';
1;

# COPYRIGHT
