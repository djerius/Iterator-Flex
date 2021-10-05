package Iterator::Flex::Grep;

# ABSTRACT: Grep Iterator Class

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.13';

use Iterator::Flex::Factory;
use Iterator::Flex::Utils qw[ THROW STATE EXHAUSTION :IterAttrs :IterStates ];
use Ref::Util;
use parent 'Iterator::Flex::Base';

use namespace::clean;

=method new

  $iterator = Ierator::Flex::Grep->new( $coderef, $iterable, ?\%pars );

Returns an iterator equivalent to running C<grep> on C<$iterable> with
the specified code.

C<$iterable> is converted into an iterator via L<Iterator::Flex::Factory/to_iterator> if required.

C<CODE> is I<not> run if C<$iterable> is exhausted.

The optional C<%pars> hash may contain standard I<signal
parameters|Iterator::Flex::Manual::Overview/Signal Parameters>.

The iterator supports the following capabilities:

=over

=item next

=item reset

=back

=cut

sub new ( $class, $code, $iterable, $pars={} ) {
    $class->_throw( parameter => "'code' parameter is not a coderef" )
      unless Ref::Util::is_coderef( $code );

    $class->SUPER::new( { code => $code, src => $iterable }, $pars );
}


sub construct ( $class, $state ) {

    $class->_throw( parameter => "'state' parameter must be a HASH reference" )
      unless Ref::Util::is_hashref( $state );

    my ( $code, $src ) = @{$state}{ qw[ code src ] };

    $src
      = Iterator::Flex::Factory->to_iterator( $src, { (+EXHAUSTION) => +THROW } );

    my $self;
    my $iterator_state;

    return {
        (+_NAME) => 'igrep',

        (+_SELF) => \$self,

        (+STATE) => \$iterator_state,

        (+NEXT) => sub {
            return $self->signal_exhaustion
              if $iterator_state == +IterState_EXHAUSTED;

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
        (+RESET)    => sub { },
        (+_DEPENDS) => $src,
    };
}

__PACKAGE__->_add_roles( qw[
      State::Closure
      Next::ClosedSelf
      Rewind::Closure
      Reset::Closure
      Current::Closure
] );

1;

# COPYRIGHT
