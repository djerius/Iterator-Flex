package Iterator::Flex::Cache;

use strict;
use warnings;

our $VERSION = '0.04';

use Carp ();
use parent 'Iterator::Flex::Base';
use Ref::Util;

## no critic ( ProhibitExplicitReturnUndef )

=method new

  $iterator = Iterator::Flex::Cache->new( $iterable );

The iterator caches the current and previous values of the passed iterator,

The returned iterator supports the following methods:

=over

=item current

=item next

=item prev

=item rewind

=item reset

=item freeze

=back

=cut


sub new {

    my $class = shift;

    $class->_construct( $_[0], undef, undef );

};

sub _construct {

    my $class = shift;

    my ( $src, $prev, $current ) = @_;

    return $class->_ITERATOR_BASE->construct(

        class => $class,

        reset => sub {
            $prev = $current = undef;
        },

        rewind => sub {
        },

        prev => sub {
            return $prev;
        },

        current => sub {
            return $current;
        },

        next => sub {

            return undef
              if $_[0]->is_exhausted;

            $prev    = $current;
            $current = $src->();

            $_[0]->set_exhausted
              if $src->is_exhausted;

            return $current;
        },

        freeze => sub {
            return [ $class, '_thaw', [ $class, $prev, $current ] ];
        },

        depends => $src,

        exhausted => 'predicate',
    );


}

sub _thaw {

    my $class = shift;

    my ( $src ) = @{ pop @_ };

    $class->_construct( $src, @_ );
}


__PACKAGE__->_add_roles(
    qw[ ExhaustedPredicate
      Rewind
      Reset
      Previous
      Current
      Serialize
      ] );


1;
