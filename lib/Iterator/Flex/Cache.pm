package Iterator::Flex::Cache;

# ABSTRACT: Cache Iterator Class

use strict;
use warnings;

our $VERSION = '0.12';

use parent 'Iterator::Flex::Base';
use Iterator::Flex::Utils qw( ITERATOR_STATE :IterAttrs );
use Iterator::Flex::Factory;
use Scalar::Util;

use namespace::clean;

=method new

  $iterator = Iterator::Flex::Cache->new( $iterable );

The iterator caches the current and previous values of C<$iterable>,
C<$iteratable> is converted into an iterator (if it is not already
one) via L<Iterator::Flex::Factory/to_iterable>).

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
    my $gpar = Ref::Util::is_hashref( $_[-1] ) ? pop : {};

    $class->_throw( parameter => 'only one parameter' )
      unless @_ == 1;

    $class->SUPER::new( { depends => [ $_[0] ] }, $gpar );
}

sub construct {
    my ( $class, $state ) = @_;

    $class->throw( parameter => "state must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $src, $prev, $current ) = @{$state}{qw[ depends prev current ]};

    $src = Iterator::Flex::Factory->to_iterator( $src->[0] );

    my $self;
    my $iterator_state;

    return {

        (+_SELF) => \$self,

        (+ITERATOR_STATE) => \$iterator_state,

        (+RESET) => sub {
            $prev = $current = undef;
        },

        (+REWIND) => sub {
        },

        (+PREV) => sub {
            return $prev;
        },

        (+CURRENT) => sub {
            return $current;
        },

        (+NEXT) => sub {

            return $current
              if $iterator_state;

            $prev    = $current;
            $current = $src->();

            $current = $self->signal_exhaustion
              if $src->is_exhausted;

            return $current;
        },

        (+FREEZE) => sub {
            return [ $class, { (+PREV) => $prev, (+CURRENT) => $current } ];
        },

        (+_DEPENDS) => $src,
    };
}



__PACKAGE__->_add_roles( qw[
      State::Closure
      Next::ClosedSelf
      Rewind::Closure
      Reset::Closure
      Prev::Closure
      Current::Closure
      Freeze
] );


1;

# COPYRIGHT
