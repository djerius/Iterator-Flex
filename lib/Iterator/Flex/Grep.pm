package Iterator::Flex::Grep;

# ABSTRACT: Grep Iterator Class

use strict;
use warnings;

our $VERSION = '0.10';

use Scalar::Util;
use List::Util;

use parent 'Iterator::Flex::Base';

=method new

  $iterator = Ierator::Flex::Grep->new( $coderef, $iterable );

Returns an iterator equivalent to running L<grep> on C<$iterable> with
the specified code.  C<$iteratable> is converted into an iterator (if
it is not already one) via C<$class->to_iterator>, which defaults to
L<Iterator::Flex::Base/to_iterable>).

C<CODE> is I<not> run if C<$iterable> returns I<undef> (that is, it is exhausted).

The iterator supports the following methods:

=over

=item next

=item reset

=back

=cut


sub construct {

    my $class = shift;

    my ( $code, $src ) = @_;
    $src = $class->to_iterator( $src );

    return {
        name => 'igrep',
        next => sub {

            foreach ( ; ; ) {
                my $rv = $src->();
                last if $src->is_exhausted;
                local $_ = $rv;
                return $rv if $code->();
            }
            $_[0]->set_exhausted;
            return undef;
        },
        reset     => sub { },
        depends   => $src,
        exhausted => 'predicate',
    };
}

__PACKAGE__->_add_roles(
    qw[
      ExhaustedPredicate
      Rewind
      Reset
      Current
      ] );


1;
