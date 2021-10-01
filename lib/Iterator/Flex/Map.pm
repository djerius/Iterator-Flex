package Iterator::Flex::Map;

# ABSTRACT: Map Iterator Class

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Utils qw( ITERATOR_STATE THROW EXHAUSTION :IterAttrs :IterStates );
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

sub new {
    my $class = shift;
    my $gpar = Ref::Util::is_hashref( $_[-1] ) ? pop : {};

    $class->_throw( parameter => 'not enough parameters' )
      unless @_ > 1;

    $class->_throw( parameter => "'code' parameter is not a coderef" )
      unless Ref::Util::is_coderef( $_[0] );

    $class->SUPER::new( { code => $_[0], src => $_[1] }, $gpar );
}

sub construct {
    my ( $class, $state ) = @_;

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

        (+ITERATOR_STATE) => \$iterator_state,

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
