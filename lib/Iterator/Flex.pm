package Iterator::Flex;

# ABSTRACT: Iterators which can be rewound and serialized

use strict;
use warnings;

our $VERSION = '0.10';

use Exporter 'import';

our @EXPORT_OK
  = qw[ iterator iter iarray icycle icache igrep imap iproduct iseq ifreeze thaw ];
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Ref::Util qw[ is_arrayref is_hashref is_ref ];
use Module::Runtime qw[ require_module ];

use Iterator::Flex::Base;

our $ITERATOR_BASE_CLASS = __PACKAGE__ . '::Base';

sub _ITERATOR_BASE { $ITERATOR_BASE_CLASS };


sub _croak {
    require Carp;
    Carp::croak( @_ );
}


=sub iterator

  $iter = iterator { CODE } ?%params;

Construct an iterator from code. The code will have access to the
iterator object through C<$_[0]>.  The optional parameters are any of
the parameters recognized by L<Iterator::Flex::Base/construct>.

 By default the code is expected to return C<undef> upon exhaustion.


=cut

sub iterator(&@) {
    $ITERATOR_BASE_CLASS->construct( next => shift, @_ );
}


=sub iter

  $iter = iter( $iterable );

Construct an iterator from an iterable thing. The iterator will
return C<undef> upon exhaustion.

 An iterable thing is

=over

=item an object

An iterable object has one or more of the following methods

=over

=item C<__iter__> or C<iter>

=item C<__next__> or C<next>

=item an overloaded C<< <> >> operator

This should return the next item.

=item an overloaded C<< &{} >> operator

This should return a subroutine which returns the next item.

=back

Additionally, if the object has the following methods, they are used
by the constructed iterator:

=over

=item C<__prev__> or C<prev>

=item C<__current__> or C<current>

=back

See L</construct_from_object>

=item an arrayref

The returned iterator will be an L<Iterator::Flex/iarray> iterator.

=item a coderef

The coderef must return the next element in the iteration.

=item a globref

=back


=cut

sub iter {
    $ITERATOR_BASE_CLASS->to_iterator( @_ );
}


=sub iarray

  $iterator = iarray( $array_ref );

Wrap an array in an iterator.

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

sub iarray {
    require Iterator::Flex::Array;
    return Iterator::Flex::Array->new( @_ );
}

=sub icache

  $iterator = icache( $iterable );

The iterator caches the current and previous values of the passed iterator,

The returned iterator supports the following methods:

=over

=item reset

=item rewind

=item next

=item prev

=item current

=item freeze

=back

=cut

sub icache {
    require Iterator::Flex::Cache;
    Iterator::Flex::Cache->new( shift, undef, undef );
}

=sub icycle

  $iterator = icycle( $array_ref );

Wrap an array in an iterator.  The iterator will continuously cycle through the array's values.

=over

=item current

=item next

=item prev

=item rewind

=item reset

=item freeze

=back

=cut

sub icycle {
    require Iterator::Flex::Cycle;
    return Iterator::Flex::Cycle->new( $_[0] );
}


=sub igrep

  $iterator = igrep { CODE } $iterable;

Returns an iterator equivalent to running L<grep> on C<$iterable> with the specified code.
C<CODE> is I<not> run if C<$iterable> returns I<undef> (that is, it is exhausted).

The iterator supports the following methods:

=over

=item next

=item reset

=back

=cut

sub igrep(&$) {
    require Iterator::Flex::Grep;
    Iterator::Flex::Grep->new( @_ );
}


=sub imap

  $iterator = imap { CODE } $iteraable;

Returns an iterator equivalent to running L<map> on C<$iterable> with the specified code.
C<CODE> is I<not> run if C<$iterable> returns I<undef> (that is, it is exhausted).

The iterator supports the following methods:

=over

=item next

=item reset

=back

=cut

sub imap(&$) {

    require Iterator::Flex::Map;
    Iterator::Flex::Map->new( @_ );
}


=sub iproduct

  $iterator = iproduct( $iterable1, $iterable2, ... );
  $iterator = iproduct( key1 => $iterable1, key2 => iterable2, ... );

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

sub iproduct {

    require Iterator::Flex::Product;
    return Iterator::Flex::Product->new( @_ );
}

=sub iseq

  # integer sequence starting at 0, incrementing by 1, ending at $end
  $iterator = iseq( $end );

  # integer sequence starting at $begin, incrementing by 1, ending at $end
  $iterator = iseq( $begin, $end );

  # real sequence starting at $begin, incrementing by $step, ending <= $end
  $iterator = iseq( $begin, $end, $step );

The iterator supports the following methods:

=over

=item current

=item next

=item prev

=item rewind

=item freeze

=back


=cut


sub iseq {
    require Iterator::Flex::Sequence;
    Iterator::Flex::Sequence->new ( @_ );
}


=sub ifreeze

  $iter = ifreeze { CODE } $iterator;

Construct a pass-through iterator which freezes the input iterator
after every call to C<next>.  C<CODE> will be passed the frozen state
(generated by calling C<$iterator->freeze> via C<$_>, with which it
can do as it pleases.

<CODE> I<is> executed when C<$iterator> returns I<undef> (that is,
when C<$iterator> is exhausted).

The returned iterator supports the following methods:

=over

=item next

=item prev

If C<$iterator> provides a C<prev> method.

=item rewind

=item freeze

=back


=cut

sub ifreeze (&$) {
    require Iterator::Flex::Freeze;
    Iterator::Flex::Freeze->new(@_);
}


=sub thaw

   $frozen = $iterator->freeze;
   $iterator = thaw( $frozen );

Restore an iterator that has been frozen.  See L</Serialization of
Iterators> for more information.


=cut

sub thaw {

    my $step = shift;

    _croak( "thaw: too many args\n" )
      if @_;

    my @steps = @$step;

    # parent data and iterator state is last
    my $exhausted = pop @steps;
    my $parent    = pop @steps;

    my @depends = map { thaw( $_ ) } @steps;

    my ( $package, $state ) = @$parent;

    _croak( "state argument for $package constructor must be a HASH or ARRAY reference ")
      unless is_hashref( $state ) || is_arrayref( $state );

    require_module( $package );
    my $new_from_state = $package->can( 'new_from_state' )
      or _croak(
        "unable to thaw: $package doesn't provide 'new_from_state' method\n" );

    if ( @depends ) {

        if ( is_hashref( $state ) ) {
            $state->{depends} = \@depends;
        }

        elsif ( is_arrayref( $state ) ) {
            push @$state, \@depends;
        }
    }

    my $iter = $package->$new_from_state( $state );
    $iter->set_exhausted( $exhausted );
    return $iter;
}

1;

# COPYRIGHT

__END__


=head1 SYNOPSIS

=head1 DESCRIPTION

C<Iterator::Flex> implements iterators with the following characteristics:

=over

=item I<next>

All iterators provide a C<next> method which advances the iterator and
returns the new value.

=item I<exhaustion>

Iterator exhaustion is signified by C<next> return C<undef>.

=item I<reset>

Iterators may optionally be rewound to their initial state

=item I<previous values>

Iterators may optionally return their previous value.

=item I<current>

Iterators return their current value.

=item I<freeze>

Iterators may optionally provide a C<freeze> method for serialization.
Iterators may be chained, and an iterator's dependencies are frozen automatically.

=back

=head2 Serialiation of Iterators

=over

=item freeze I<optional>

A subroutine which returns an array reference with the following elements, in the specified order :

=over

=item 1

The name of the package containing the thaw subroutine.

=item 2

The name of the thaw subroutine.

=item 3

The data to be passed to the thaw routine.  The routine will be called
as:

  thaw( @{$data}, ?$depends );

if C<$data> is an arrayref,

  thaw( %{$data}, ?( depends => $depends )  );

if C<$data> is a hashref, or

  thaw( $data, ?$depends );

for any other type of data.

Dependencies are passed to the thaw routine only if they are present.

=back

=back

=head1 SUBROUTINES

=head1 METHODS

Not all iterators support all methods.

=over

=item prev

  $value = $iter->prev;

Returns the previous value of the iterator.  If the iterator was never
advanced, this returns C<undef>.  If the iterator is exhausted, this
returns the last retrieved value. Use the L<state> method to determine
which state the iterator is in.

=item current

  $value = $iter->current;

Returns the current value of the iterator.  If the iterator was never
advanced, this returns undef.  If the iterator is exhausted, this
returns C<undef>.  Use the L<state> method to determine which state
the iterator is in.

=item next

  $value = $iter->next;

Return the next value from the iterator.

=item rewind

  $iter->rewind;

Resets the iterator so that the next value returned is the very first
value.  It should not affect the results of the L<prev> and L<current>
methods.

=item reset

  $iter->reset;

Resets the iterator to its initial state.  The iterator's state is not
changed.

=back


=head1 SEE ALSO
