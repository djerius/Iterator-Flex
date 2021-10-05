package Iterator::Flex;

# ABSTRACT: Iterators with flexible behaviors

use v5.28.0;
our $VERSION = '0.13';

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
an exception, and provide a test for exhaustion via the C<is_exhausted> method.

=item *

wrap existing iterators so that they have the same exhaustion interface
as your own iterators

=item *

provide history via C<prev> and C<current> methods.

=back

These are I<optional> things behaviors that an iterator can support.  Not all
iterators need the bells and whistles, but sometimes they are very handy.

=head2 Where are the iterators?

See L<Iterator::Flex::Common> for a set of common iterators.  These
are pre-made for you.  See L<Iterator::Flex::Manual::Using> for how to
use them.

=head2 I need to write my own.

See L<Iterator::Flex::Manual::Authoring> for how to write your own
flexible iterators.

See L<Iterator::Flex::Manual::Internals> for how everything links
together.

=head2 Show me the Manual

L<Iterator::Flex::Manual>

=head2 What doesn't work?  What should frighten me away?

L<Iterator::Flex::Manual::Caveats>
