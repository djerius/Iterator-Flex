package Iterator::Flex::Product;

# ABSTRACT: An iterator which produces a Cartesian product of iterators

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Utils qw( RETURN STATE EXHAUSTION :IterAttrs :IterStates );
use Iterator::Flex::Factory;
use parent 'Iterator::Flex::Base';
use Ref::Util;
use List::Util;

use experimental 'declared_refs';

use namespace::clean;

=method new

  $iterator = Iterator::Flex::Product->new( $iterable1, $iterable2, ... );
  $iterator = Iterator::Flex::Product->new( key1 => $iterable1,
                              key2 => iterable2, ... );

Returns an iterator which produces a Cartesian product of the input iterables.
If the input to B<iproduct> is a list of iterables, C<$iterator> will return an
array reference containing an element from each iterable.

If the input is a list of key, iterable pairs, C<$iterator> will return a
hash reference.

All of the iterables must support the C<rewind> method.

The iterator supports the following methods:

=over

=item current

=item next

=item reset

=item rewind

=item freeze

This iterator may be frozen only if all of the iterables support the
C<prev> or C<__prev__> method.

=back

=cut


sub new {
    my $class = shift;
    my $gpar = Ref::Util::is_hashref( $_[-1] ) ? pop : {};

    $class->_throw( parameter => 'not enough parameters' )
      unless @_;

    my @iterators;
    my @keys;

    # distinguish between ( key => iterator, key =>iterator ) and ( iterator, iterator );
    if ( Ref::Util::is_ref( $_[0] ) ) {
        @iterators = @_;
    }
    else {
        $class->_throw( parameter => 'expected an even number of arguments' )
          if  @_ % 2;

        while ( @_ ) {
            push @keys, shift;
            push @iterators, shift;
        }
    };

    # can only work if the iterators support a rewind method
    $class->_throw( parameter => "all iterables must provide a rewind method" )
      unless List::Util::all  { defined $class->_can_meth( $_, 'rewind' ) } @iterators;

    $class->SUPER::new( { keys => \@keys, depends =>\@iterators, value => [] }, $gpar );
}

sub construct {
    my ( $class, $state ) = @_;

    $class->_throw( parameter => "state must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    $state->{value} //= [];

    my ( \@depends, \@keys, \@value, $thaw )
      = @{$state}{qw[ depends keys value thaw ]};

    $class->_throw(
        parameter => "number of keys not equal to number of iterators" )
      if @keys && @keys != @depends;

    my @iterators = map {
        Iterator::Flex::Factory->to_iterator( $_, { (+EXHAUSTION) => +RETURN } )
    } @depends;

    @value = map { $_->current } @iterators
      if $thaw;

    my @set = ( 1 ) x @value;

    my $self;
    my $iterator_state;
    my %params = (

        (+_SELF) => \$self,

        (+STATE) => \$iterator_state,

        (+NEXT) => sub {
            return $self->signal_exhaustion if $iterator_state == +IterState_EXHAUSTED;

            # first time through
            if ( !@value ) {

                for my $iter ( @iterators ) {
                    push @value, $iter->();

                    if ( $iter->is_exhausted ) {
                        return $self->signal_exhaustion;
                    }
                }

                @set = ( 1 ) x @value;
            }

            else {

                $value[-1] = $iterators[-1]->();
                if ( $iterators[-1]->is_exhausted ) {
                    $set[-1] = 0;
                    my $idx = @iterators - 1;
                    while ( --$idx >= 0 ) {
                        $value[$idx] = $iterators[$idx]->();
                        last unless $iterators[$idx]->is_exhausted;
                        $set[$idx] = 0;
                    }

                    if ( !$set[0] ) {
                        return $self->signal_exhaustion;
                    }

                    while ( ++$idx < @iterators ) {
                        $iterators[$idx]->rewind;
                        $value[$idx] = $iterators[$idx]->();
                        $set[$idx]   = 1;
                    }
                }

            }
            if ( @keys ) {
                my %value;
                @value{@keys} = @value;
                return \%value;
            }
            else {
                return [@value];
            }
        },

        (+CURRENT) => sub {
            return undef if !@value;
            return $self->signal_exhaustion if $iterator_state eq +IterState_EXHAUSTED;
            if ( @keys ) {
                my %value;
                @value{@keys} = @value;
                return \%value;
            }
            else {
                return [@value];
            }
        },

        (+RESET)  => sub { @value = () },
        (+REWIND) => sub { @value = () },
        (+_DEPENDS) => \@iterators,
    );

    # can only freeze if the iterators support a current method
    if (
        List::Util::all { defined $class->_can_meth( $_, 'current' ) }
        @iterators
      )
    {

        $params{+FREEZE} = sub {
            return [ $class, { keys => \@keys } ];
        };
        $params{+_ROLES} = ['Freeze'];
    }

    return { %params, (+_NAME) => 'iproduct' };
}


__PACKAGE__->_add_roles( qw[
      State::Closure
      Next::ClosedSelf
      Current::Closure
      Reset::Closure
      Rewind::Closure
] );

1;

# COPYRIGHT
