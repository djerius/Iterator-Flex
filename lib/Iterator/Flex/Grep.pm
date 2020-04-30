package Iterator::Flex::Grep;

# ABSTRACT: Grep Iterator Class

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Factory;
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

    # my $class =
    shift;

    my ( $code, $src ) = @_;
    $src = Iterator::Flex::Factory::to_iterator( $src,
        on_exhaustion_return => undef );

    my $self;

    return {
        name => 'igrep',

        self => \$self,

        next => sub {

            foreach ( ; ; ) {
                my $rv = $src->();
                last if $src->is_exhausted;
                local $_ = $rv;
                return $rv if $code->();
            }
            return $self->signal_exhaustion;
        },
        reset   => sub { },
        depends => $src,
    };
}

__PACKAGE__->_add_roles( qw[
      Next::ClosedSelf
      Next
      Rewind
      Reset
      Current
] );

1;

# COPYRIGHT
