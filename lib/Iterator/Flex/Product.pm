package Iterator::Flex::Product;

# ABSTRACT: An iterator which produces a Cartesian product of iterators

use strict;
use warnings;

our $VERSION = '0.07';

use Carp ();
use parent 'Iterator::Flex::Base';
use Ref::Util;
use List::Util ();

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

    $class->_construct( [@_] );
}

sub _construct {

    my $class = shift;
    my ( $iterators, $value ) = @_;

    $value = [] unless defined $value;

    my @keys;
    my @iterator;

    # distinguish between ( key => iterator, key =>iterator ) and ( iterator, iterator );
    if ( Ref::Util::is_ref( $iterators->[0] ) ) {

        @iterator = map { $class->to_iterator( $_ ) } @$iterators;
    }

    else {
        @keys = List::Util::pairkeys @$iterators;
        @iterator = map { $class->to_iterator( $_ ) } List::Util::pairvalues @$iterators;
    }

    # can only work if the iterators support a rwind method
    croak( "iproduct requires that all iteratables provide a rewind method\n" )
      unless @iterator == grep { defined }
      map { $class->_ITERATOR_BASE->_can_meth( $_, 'rewind' ) } @iterator;

    my @value = @$value;
    my @set   = ( 1 ) x @value;

    my %params = (
        next => sub {
            return undef if $_[0]->is_exhausted;

            # first time through
            if ( !@value ) {

                for my $iter ( @iterator ) {
                    push @value, $iter->();

                    if ( $iter->is_exhausted ) {
                        $_[0]->set_exhausted;
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
                        $_[0]->set_exhausted;
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
            return undef if !@value || $_[0]->is_exhausted;
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
        map { $class->_ITERATOR_BASE->_can_meth( $_, 'current' ) } @iterator
      )
    {

        $params{freeze} = sub {
            return [ $class, '_thaw', [ $class, \@keys ] ];
          }
    }

    $class ->_ITERATOR_BASE->construct(
        %params,
        exhausted => 'predicate',
        name      => 'iproduct'
    );
}

sub _thaw {

    my $class = shift;

    my ( $keys, $iterators ) = @_;
    my @value = map { $_->current } @$iterators;

    if ( @$keys ) {

        @$keys == @$iterators
          or croak(
            "iproduct thaw: number of keys not equal to number of iterators\n"
          );

        $iterators = [ map { $keys->[$_], $iterators->[$_] } 0 .. @$keys - 1 ];
    }

    $class->_construct( $iterators, \@value );
}


1;
