package Iterator::Flex::Role::Exhausted::Registry;

# ABSTRACT: Role for iterator which handles set_exhausted and is_exhausted predicate.

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;
use Iterator::Flex::Utils qw( :default IS_EXHAUSTED ITERATOR );

use namespace::clean;

=method set_exhausted

  $iter->set_exhausted;

Set the iterator's state to exhausted

=cut

sub set_exhausted {
    $REGISTRY{ refaddr $_[0] }{+ITERATOR}{+IS_EXHAUSTED} = 1;
}

sub _reset_exhausted {
    $REGISTRY{ refaddr $_[0] }{+ITERATOR}{+IS_EXHAUSTED} = 0;
}


=method is_exhausted

  $bool = $iter->is_exhausted;

Returns true if the iterator is exhausted and there are no more values
available.  L<current> and L<next> will return C<undef>.  L<prev> will
return the last valid value returned by L<next>.

L<is_exhausted> is true only after L<next> has been called I<after>
the last valid value has been returned by a previous call to
L<next>. In other words, if C<$iter->next> returns the last valid
value, the state is still I<active>.  The next call to C<$iter->next>
will switch the iterator state to I<exhausted>.


=cut

sub is_exhausted {
    !! $REGISTRY{ refaddr $_[0] }{+ITERATOR}{+IS_EXHAUSTED};
}


1;

# COPYRIGHT
