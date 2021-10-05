package Iterator::Flex::Cache;

# ABSTRACT: Cache Iterator Class

use strict;
use warnings;
use experimental qw( signatures postderef );

our $VERSION = '0.13';

use parent 'Iterator::Flex::Base';
use Iterator::Flex::Utils qw( STATE :IterAttrs :IterStates throw_failure );
use Iterator::Flex::Factory;
use Scalar::Util;
use Ref::Util;

use namespace::clean;

=method new

  $iterator = Iterator::Flex::Cache->new( $iterable, ?\%pars );

The iterator caches values of C<$iterable> (by default, the previous and current values),

C<$iterable> is converted into an iterator via L<Iterator::Flex::Factory/to_iterator> if required.

The optional C<%pars> hash may contain standard I<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters> as well
as the following model parameters:

=over

=item capacity => I<integer>

The size of the cache.  It defaults to C<2>.

=back

The returned iterator supports the following capabilities:

=over

=item current

=item next

=item prev

=item rewind

=item reset

=item freeze

=back

=cut


sub new ( $class, $iterable, $pars={} ) {

    throw_failure( parameter => '"pars" argument must be a hash' )
      unless Ref::Util::is_hashref( $pars );

    my %pars = $pars->%*;

    my $capacity = delete $pars{capacity} // 2;

    $class->SUPER::new( {
            capacity => $capacity,
            depends  => [ Iterator::Flex::Factory->to_iterator( $iterable ) ],
        },
        \%pars
    );
}

sub construct ( $class, $state ) {

    $class->_throw( parameter => "state must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $src, $capacity, $idx, $cache ) = @{$state}{qw[ depends capacity idx cache ]};
    $src = $src->[0];
    $idx //= -1;
    $cache //= [];

    my $self;
    my $iterator_state;

    return {

        (+_SELF) => \$self,

        (+STATE) => \$iterator_state,

        (+RESET) => sub {
            $idx = -1;
            @{ $cache } = ();
        },

        (+REWIND) => sub {
        },

        (+PREV) => sub {
            return defined $idx? $cache->[ ($idx-1) % $capacity] : undef;
        },

        (+CURRENT) => sub {
            return defined $idx? $cache->[ $idx % $capacity] : undef;
        },

        (+NEXT) => sub {

            return $self->signal_exhaustion
              if $iterator_state == +IterState_EXHAUSTED;

            $idx = ++$idx % $capacity;
            my $current = $cache->[$idx] = $src->();

            return $self->signal_exhaustion
              if $src->is_exhausted;

            return $current;
        },

        (+METHODS) => {
            at => sub ( $, $at ) {
                $cache->[ ( $at - $idx ) % $capacity ];
            },
        },

        (+FREEZE) => sub {
            return [ $class, { idx => $idx, capacity => $capacity, cache => $cache  } ];
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
