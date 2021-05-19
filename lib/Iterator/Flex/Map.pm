package Iterator::Flex::Map;

# ABSTRACT: Map Iterator Class

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Factory;
use parent 'Iterator::Flex::Base';

=method new

  $iterator = Ierator::Flex::Map->new( $coderef, $iterable );

Returns an iterator equivalent to running L<map> on C<$iterable> with
the specified code.  C<$iteratable> is converted into an iterator (if
it is not already one) via  L<Iterator::Flex::Factory/to_iterable>).

C<CODE> is I<not> run if C<$iterable> returns I<undef> (that is, it is
exhausted).

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

    $src = Iterator::Flex::Factory->to_iterator( $src,
        on_exhaustion_return => undef );

    my $self;

    return {
        _name => 'imap',

        _self => \$self,

        next => sub {
            my $value = $src->();
            if ( $src->is_exhausted ) {
                return $self->signal_exhaustion;
            }
            local $_ = $value;
            return $code->();
        },
        reset     => sub { },
        _depends   => $src,
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
