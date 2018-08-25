package Iterator::Flex::Sequence;

# ABSTRACT: Numeric Sequence Iterator Class

use strict;
use warnings;

our $VERSION = '0.10';

use Scalar::Util;
use List::Util;

use parent 'Iterator::Flex::Base';

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

sub construct {

    my $class = shift;

    # only three arguments
    splice( @_, 3 );

    # add history
    push @_, ( undef ) x 3;

    $class->construct_from_state( @_ );
}


# must be called with ( $next, $current, $prev) as last
# three arguments.
sub construct_from_state {

    my $class = shift;

    # these get pushed on as $prev, $current, $next, so pop in opposite
    # order
    my ( $next, $current, $prev ) = ( pop, pop, pop );

    $class->_croak( "$class: arguments must be numbers\n" )
      if List::Util::first { !Scalar::Util::looks_like_number( $_ ) } @_;

    my ( $self, $begin, $end, $step, $iter );

    my %params;

    if ( @_ < 3 ) {

        $end   = pop;
        $begin = shift;

        $begin = 0      unless defined $begin;
        $next  = $begin unless defined $next;

        %params = (
            next => sub {
                if ( $next > $end ) {
                    if ( !$self->is_exhausted ) {
                        $prev    = $current;
                        $current = undef;
                        $self->set_exhausted;
                    }
                    return undef;
                }
                $prev    = $current;
                $current = $next++;
                return $current;
            },
            freeze => sub {
                [ $class, [ $begin, $end, $prev, $current, $next ] ];
            },
        );
    }

    else {

        ( $begin, $end, $step, $iter ) = @_;

        $class->_croak(
            "sequence will be inifinite as \$step is zero or has the incorrect sign\n"
          )
          if ( $begin < $end && $step <= 0 ) || ( $begin > $end && $step >= 0 );

        $next = $begin unless defined $next;
        $iter = 0      unless defined $iter;

        %params = (
            freeze => sub {
                [
                    $class,
                    [ $begin, $end, $step, $iter, $prev, $current, $next ] ];
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

        set_self => sub {
            $self = shift;
            Scalar::Util::weaken( $self );
        },
    };

}

__PACKAGE__->_add_roles( qw[
      ExhaustedPredicate
      Rewind
      Reset
      Prev
      Current
      Freeze
] );


1;
