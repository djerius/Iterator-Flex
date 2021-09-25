package Iterator::Flex::Sequence;

# ABSTRACT: Numeric Sequence Iterator Class

use strict;
use warnings;

use experimental qw( postderef );

our $VERSION = '0.12';

use Scalar::Util;
use List::Util;

use parent 'Iterator::Flex::Base';
use Iterator::Flex::Utils qw( IS_EXHAUSTED );

use namespace::clean;

=method new

  # integer sequence starting at 0, incrementing by 1, ending at $end
  $iterator = Iterator::Flex::Sequence->new( $end );

  # integer sequence starting at $begin, incrementing by 1, ending at $end
  $iterator = Iterator::Flex::Sequence->new( $begin, $end );

  # real sequence starting at $begin, incrementing by $step, ending <= $end
  $iterator = Iterator::Flex::Sequence->new( $begin, $end, $step );

The iterator supports the following methods:

=over

=item current

=item next

=item prev

=item rewind

=item freeze

=back


=cut

sub new {
    my $class = shift;
    my $gpar = Ref::Util::is_hashref( $_[-1] ) ? pop : {};

    $class->_throw( parameter => "incorrect number of arguments for sequence" )
      if @_ < 1 || @_ > 3 ;

    my %state;
    $state{step}  = pop if @_ == 3;
    $state{end}   = pop;
    $state{begin} = pop;


    $class->SUPER::new( \%state, $gpar );
}

sub construct {
    my ( $class, $state ) = @_;

    $class->_throw( parameter => "$class: arguments must be numbers\n" )
      if List::Util::first { !Scalar::Util::looks_like_number( $_ ) };

    my ( $begin, $end, $step, $iter, $next, $current, $prev )
      = @{$state}{qw[ begin end step iter next current prev ]};

    my $self;
    my $is_exhausted;

    my %params;

    if ( !defined $step ) {

        $begin = 0      unless defined $begin;
        $next  = $begin unless defined $next;

        %params = (
            next => sub {
                if ( $next > $end ) {
                    if ( !$self->is_exhausted ) {
                        $prev    = $current;
                        $current = $self->signal_exhaustion;
                    }
                    return $current;
                }
                $prev    = $current;
                $current = $next++;
                return $current;
            },
            freeze => sub {
                [
                    $class,
                    {
                        begin   => $begin,
                        end     => $end,
                        prev    => $prev,
                        current => $current,
                        next    => $next,
                    },
                ]
            },
        );
    }

    else {

        $class->_throw(
            "sequence will be inifinite as \$step is zero or has the incorrect sign"
          )
          if ( $begin < $end && $step <= 0 ) || ( $begin > $end && $step >= 0 );

        $next = $begin unless defined $next;
        $iter = 0      unless defined $iter;

        %params = (
            freeze => sub {
                [
                    $class,
                    {
                        begin   => $begin,
                        end     => $end,
                        step    => $step,
                        iter    => $iter,
                        prev    => $prev,
                        current => $current,
                        next    => $next,
                    } ]
            },

            next => $begin < $end
            ? sub {
                if ( $next > $end ) {
                    if ( !$self->is_exhausted ) {
                        $prev    = $current;
                        $current = undef;
                        $self->set_exhausted;
                    }
                    return undef;
                }
                $prev    = $current;
                $current = $next;
                $next    = $begin + ++$iter * $step;
                return $current;
            }
            : sub {
                if ( $next < $end ) {
                    if ( !$self->is_exhausted ) {
                        $prev    = $current;
                        $current = undef;
                        $self->set_exhausted;
                    }
                    return undef;
                }
                $prev    = $current;
                $current = $next;
                $next    = $begin + ++$iter * $step;
                return $current;
            },
        );
    }

    return {
        %params,
        current => sub { $current },
        prev    => sub { $prev },
        rewind  => sub {
            $next = $begin;
            $iter = 0;
        },
        reset => sub {
            $prev = $current = undef;
            $next = $begin;
            $iter = 0;
        },

        _self => \$self,

        IS_EXHAUSTED,
        => \$is_exhausted,
    };

}

__PACKAGE__->_add_roles( qw[
      ::Exhausted::Closure
      ::Next::ClosedSelf
      Next
      Rewind
      Reset
      Prev
      Current
      Freeze
] );

1;

# COPYRIGHT
