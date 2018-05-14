package Iterator::Flex::Sequence;

# ABSTRACT: Numeric Sequence Iterator Class

use strict;
use warnings;

our $VERSION = '0.08';

use Carp ();
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

sub new {

    my $class = shift;

    # only three arguments
    splice( @_, 3 );

    # add history
    push @_, ( undef ) x 3;

    $class->_construct( @_ );
};


sub _construct {

    my $class = shift;

    # these get pushed on as $prev, $current, $next, so pop in opposite
    # order
    my ( $next, $current, $prev ) = ( pop, pop, pop );

    Carp::croak( "$class: arguments must be numbers\n" )
      if List::Util::first { ! Scalar::Util::looks_like_number( $_ ) } @_;

    my ( $begin, $end, $step );
    my %params;

    if ( @_ < 3 ) {

        $end   = pop;
        $begin = shift;

        $begin = 0      unless defined $begin;
        $next  = $begin unless defined $next;

        %params = (
            next => sub {
                if ( $next > $end ) {
                    if ( !$_[0]->is_exhausted ) {
                        $prev    = $current;
                        $current = undef;
                        $_[0]->set_exhausted;
                    }
                    return undef;
                }
                $prev    = $current;
                $current = $next++;
                return $current;
            },
            freeze => sub {
                [
                    $class, '_construct',
                    [ $class, $begin, $end, $prev, $current, $next ] ];
            },
        );
    }

    else {

        ( $begin, $end, $step ) = @_;

        croak(
            "sequence will be inifinite as \$step is zero or has the incorrect sign\n"
          )
          if ( $begin < $end && $step <= 0 ) || ( $begin > $end && $step >= 0 );

        $next = $begin unless defined $next;

        %params = (
            freeze => sub {
                [
                    $class, '_construct',
                    [ $class, $begin, $end, $step, $prev, $current, $next ] ];
            },

            next => $begin < $end
            ? sub {
                if ( $next > $end ) {
                    if ( !$_[0]->is_exhausted ) {
                        $prev    = $current;
                        $current = undef;
                        $_[0]->set_exhausted;
                    }
                    return undef;
                }
                $prev    = $current;
                $current = $next;
                $next += $step;
                return $current;
            }
            : sub {
                if ( $next < $end ) {
                    if ( !$_[0]->is_exhausted ) {
                        $prev    = $current;
                        $current = undef;
                        $_[0]->set_exhausted;
                    }
                    return undef;
                }
                $prev    = $current;
                $current = $next;
                $next += $step;
                return $current;
            },
        );
    }

    return $class->_ITERATOR_BASE->construct(
        %params,
        class     => $class,
        exhausted => 'predicate',
        current   => sub { $current },
        prev      => sub { $prev },
        rewind    => sub {
            $next = $begin;
        },
        reset => sub {
            $prev = $current = undef;
            $next = $begin;
        },
    );

}

__PACKAGE__->_add_roles(
    qw[ ExhaustedPredicate
      Rewind
      Reset
      Previous
      Current
      Serialize
      ] );


1;
