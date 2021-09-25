package Iterator::Flex;

# ABSTRACT: Iterators with flexible behaviors

use 5.10.0;
1;

# COPYRIGHT

__END__


=head1 SYNOPSIS

=head1 DESCRIPTION

Note! B<< C<Iterator::Flex> is alpha quality software. >>

=head2 What is It?

C<Iterator::Flex> provides iterators that can:

=over

=item *

rewind to the beginning, keeping track of state (e.g. cycles which
always know the previous value).

=item *

reset to the initial state

=item *

serialize, so that you can restart from where you left off,

=item *

signal exhaustion by returning a sentinel value (e.g. C<undef>) or throwing
an exception

=item *

wrap existing iterators so that they have the same exhaustion interface
as your own iterators

=item *

provide history via C<prev> and C<current> methods.

=back

These are I<optional> things behaviors that an iterator can support.  Not all
iterators need the bells and whistles, but sometimes they are very handy.

=head2 Where are the iterators?

See I<Iterator::Flex::Common> for a set of common iterators.  These
are premade for you.  See I<Iterator::Flex::Manual::Using> for how to
use an C<Iterator::Flex::Iterator>.

=head3 I need to write my own.

See I<Iterator::Flex::Manual::Internals> for how everything links
together.

See I<Iterator::Flex::Manual::Authoring> for how to write your own
flexible iterators.

C<Iterator::Flex> implements iterators with the following
characteristics:

=over

=item I<next>

All iterators provide a C<next> method which advances the iterator and
returns the new value.

=item I<exhaustion>

=over

=item *

The C<next> method indicates exhaustion either by C<next> returning a
sentinel (e.g. C<undef>) or by throwing an exception.

=item *

The C<is_exhausted> method returns true if the iterator is exhausted.
In general, an iterator cannot know if it is exhausted until after a
call to L</next> has signalled exhaustion.

For example, if an iterator is reading lines from a stream, it cannot
know that it is at the last line.  It must attempt to read a line,
then fail, before it knows it is exhausted.

=back

=item I<reset>

Iterators may optionally be reset to their initial state.

=item I<rewind>

Iterators may optionally be rewound, so that iterations may
cycle. This differs from a reset in that the iterator will correctly
return the previous value (if it provides that functionality).

=item I<previous values>

Iterators may optionally return their previous value.

=item I<current>

Iterators return their current value.

=item I<freeze>

Iterators may optionally provide a C<freeze> method for serialization.
Iterators may be chained, and an iterator's dependencies are frozen automatically.

=back

=head2 This Module

This module provides a generic generator for iterators (L</iterator>) as
well as friendly interfaces to special purpose iterators.  To create


=head2 Serialization of Iterators

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
