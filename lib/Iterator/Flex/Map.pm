package Iterator::Flex::Map;

# ABSTRACT: Map Iterator Class

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Utils qw( IS_EXHAUSTED THROW EXHAUSTION );
use Iterator::Flex::Factory;
use Ref::Util;
use parent 'Iterator::Flex::Base';

use namespace::clean;

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

    unless ( @_ == 1 && Ref::Util::is_arrayref( $_[0] ) ) {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "incorrect type or number of arguments" );
    }

    my ( $code, $src ) = @{ $_[0] };

    $src = Iterator::Flex::Factory->to_iterator( $src,
        { EXHAUSTION, => THROW } );

    my $self;
    my $is_exhausted;

    return {
        _name => 'imap',

        _self => \$self,

        IS_EXHAUSTED, => \$is_exhausted,

        next => sub {
            return $self->signal_exhaustion if $is_exhausted;

            my $ret = eval {
                my $value = $src->();
                local $_ = $value;
                $code->();
            };
            if ( $@ ne '' ) {
                die $@
                  unless Ref::Util::is_blessed_ref( $@ )
                  && $@->isa( 'Iterator::Flex::Failure::Exhausted' );
                return $self->signal_exhaustion;
            }
            return $ret;
        },
        reset    => sub { },
        _depends => $src,
    };
}


__PACKAGE__->_add_roles( qw[
      ::Exhausted::Closure
      ::Next::ClosedSelf
      Next
      Rewind
      Reset
      Current
] );

1;

# COPYRIGHT
