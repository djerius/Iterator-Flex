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
      Exhausted::Closure
      Next::ClosedSelf
      Rewind
      Reset
      Current
] );

1;

# COPYRIGHT
