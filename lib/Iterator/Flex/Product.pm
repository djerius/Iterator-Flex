package Iterator::Flex::Product;

# ABSTRACT: An iterator which produces a Cartesian product of iterators

use strict;
use warnings;

our $VERSION = '0.10';

use Iterator::Flex::Factory;
use parent 'Iterator::Flex::Base';
use Ref::Util;
use List::Util;

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


sub construct {

    my $class = shift;

    $class->construct_from_state( { iterators => [ @_ ] } );
}

sub construct_from_state {

    my ( $class, $state ) = @_;

    $class->_croak( "state must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $iterators, $value ) = @{$state}{ qw[ iterators value ] };

    $value = [] unless defined $value;

    my @keys;
    my @iterator;

    # distinguish between ( key => iterator, key =>iterator ) and ( iterator, iterator );
    if ( Ref::Util::is_ref( $iterators->[0] ) ) {

        @iterator = map { Iterator::Flex::Factory::to_iterator( $_ ) } @$iterators;
    }

    else {
        @keys = List::Util::pairkeys @$iterators;
        @iterator = map { Iterator::Flex::Factory::to_iterator( $_ ) } List::Util::pairvalues @$iterators;
    }

    # can only work if the iterators support a rwind method
    $class->_croak( "all iteratables must provide a rewind method\n" )
      unless @iterator == grep { defined }
      map { $class->_can_meth( $_, 'rewind' ) } @iterator;

    my @value = @$value;
    my @set   = ( 1 ) x @value;

    my $self;
    my %params = (

        set_self => sub {
            $self = shift;
            Scalar::Util::weaken( $self );
        },

        next => sub {
            return undef if $self->is_exhausted;

            # first time through
            if ( !@value ) {

                for my $iter ( @iterator ) {
                    push @value, $iter->();

                    if ( $iter->is_exhausted ) {
                        $self->set_exhausted;
                        return undef;
                    }
                }

                @set = ( 1 ) x @value;
            }

            else {

                $value[-1] = $iterator[-1]->();
                if ( $iterator[-1]->is_exhausted ) {
                    $set[-1] = 0;
                    my $idx = @iterator - 1;
                    while ( --$idx >= 0 ) {
                        $value[$idx] = $iterator[$idx]->();
                        last unless $iterator[$idx]->is_exhausted;
                        $set[$idx] = 0;
                    }

                    if ( !$set[0] ) {
                        $self->set_exhausted;
                        return undef;
                    }

                    while ( ++$idx < @iterator ) {
                        $iterator[$idx]->rewind;
                        $value[$idx] = $iterator[$idx]->();
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

        current => sub {
            return undef if !@value || $self->is_exhausted;
            if ( @keys ) {
                my %value;
                @value{@keys} = @value;
                return \%value;
            }
            else {
                return [@value];
            }
        },
        reset  => sub { @value = () },
        rewind => sub { @value = () },
        depends => \@iterator,
    );

    # can only freeze if the iterators support a prev method
    if (
        @iterator == grep { defined }
        map { $class->_can_meth( $_, 'current' ) } @iterator
      )
    {

        $params{freeze} = sub {
            return [ $class, { keys => \@keys } ];
        };
        $params{_roles} = [ 'Freeze' ];
    }

    return {
        %params,
        exhausted => 'predicate',
        name      => 'iproduct'
    };
}

sub new_from_state {

    my ( $class, $state ) = @_;

    my ( $keys, $iterators ) = @{$state}{ 'keys', 'depends' };
    my @value = map { $_->current } @$iterators;

    if ( @$keys ) {

        @$keys == @$iterators
          or $class->_croak(
            "number of keys not equal to number of iterators\n"
          );

        $iterators = [ map { $keys->[$_], $iterators->[$_] } 0 .. @$keys - 1 ];
    }

    $class->new_from_attrs( $class->construct_from_state( { iterators => $iterators,
                                                            value => \@value } ) );
}

__PACKAGE__->_add_roles( qw[
      ExhaustedPredicate
      Current
      Reset
      Rewind
] );

1;
