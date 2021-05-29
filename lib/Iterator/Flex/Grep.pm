package Iterator::Flex::Grep;

# ABSTRACT: Grep Iterator Class

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Factory;
use Iterator::Flex::Utils qw[ THROW IS_EXHAUSTED EXHAUSTION ];
use Ref::Util;
use parent 'Iterator::Flex::Base';

use namespace::clean;

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

    $class->_throw( parameter => "incorrect type or number of arguments" )
      unless @_ == 1 && Ref::Util::is_arrayref( $_[0] );

    my ( $code, $src ) = @{ $_[0] };

    $src
      = Iterator::Flex::Factory->to_iterator( $src, { EXHAUSTION, => THROW } );

    my $self;
    my $is_exhausted;

    return {
        _name => 'igrep',

        _self => \$self,

        IS_EXHAUSTED, => \$is_exhausted,

        next => sub {
            return $self->signal_exhaustion
              if $is_exhausted;

            my $ret = eval {
                foreach ( ; ; ) {
                    my $rv = $src->();
                    local $_ = $rv;
                    return $rv if $code->();
                }
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
