package Iterator::Flex::Map;

# ABSTRACT: Map Iterator Class

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.12';

use Iterator::Flex::Utils qw( STATE THROW EXHAUSTION :IterAttrs :IterStates );
use Iterator::Flex::Factory;
use Ref::Util;
use parent 'Iterator::Flex::Base';

use namespace::clean;

=method new

  $iterator = Ierator::Flex::Map->new( $coderef, $iterable, ?\%pars );

Returns an iterator equivalent to running C<map> on C<$iterable> with
the specified code.

C<CODE> is I<not> run if C<$iterable> is exhausted.

If required, C<$iterable> is converted into an iterator via
C<$class->to_iterator>.

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
        (+_NAME) => 'imap',

        (+_SELF) => \$self,

        (+STATE) => \$iterator_state,

        (+NEXT) => sub {
            return $self->signal_exhaustion if $iterator_state == +IterState_EXHAUSTED;

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

        (+RESET)   => sub { },
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
