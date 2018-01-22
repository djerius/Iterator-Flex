package Iterator::Flex;

# ABSTRACT: Iterators which can be rewound and serialized

use strict;
use warnings;

our $VERSION = '0.04';

use Exporter 'import';

our @EXPORT_OK
  = qw[ iterator iter iarray icache igrep imap iproduct iseq ifreeze thaw ];
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Carp;
use Scalar::Util qw[ blessed looks_like_number ];
use Ref::Util qw[ is_arrayref is_hashref is_ref ];
use Module::Runtime qw[ require_module ];
use List::Util qw[ pairkeys pairvalues all first ];

## no critic ( ProhibitExplicitReturnUndef ProhibitSubroutinePrototypes)

use Iterator::Flex::Iterator;

our $ITERATOR_CLASS = __PACKAGE__ . '::Iterator';


=sub iterator

  $iter = iterator { CODE }, ?%params;

Construct an iterator from code. The code will have access to the
iterator object through C<$_[0]>.  The optional parameters are any of
the parameters recognized by L<Iterator::Flex::Iterator/construct>.

 By default the code is expected to return C<undef> upon exhaustion.


=cut

sub iterator(&%) {
    $ITERATOR_CLASS->construct( next => $_[0], @_ );
}


=sub iter

  $iter = iter( $iterable );

Construct an iterator from an iterable thing. The iterator will
return C<undef> upon exhaustion.

 An iterable thing is

=over

=item an object

An iterable object has one or more of the following methods

=over

=item C<__iter__> or C<iter>

=item C<__next__> or C<next>

=item an overloaded C<< <> >> operator

This should return the next item.

=item an overloaded C<< &{} >> operator

This should return a subroutine which returns the next item.

=back

Additionally, if the object has the following methods, they are used
by the constructed iterator:

=over

=item C<__prev__> or C<prev>

=item C<__current__> or C<current>

=back

See L</construct_from_object>

=item an arrayref

The returned iterator will be an L<Iterator::Flex/iarray> iterator.

=item a coderef

The coderef must return the next element in the iteration.

=item a globref

=back


=cut

sub iter {

    return iterator { return }
    unless @_;

    $ITERATOR_CLASS->construct_from_iterable( @_ );
}


=sub iarray

  $iterator = iarray( $array_ref );

Wrap an array in an iterator.

The returned iterator supports the following methods:

=over

=item current

=item next

=item prev

=item rewind

=item reset

=item freeze

=back

=cut

sub iarray {
    return _iarray( $_[0] );
}

sub _iarray {

    my ( $arr, $prev, $current, $next ) = @_;

    croak 'Argument to iarray must be ARRAY reference'
      unless is_arrayref( $arr );

    my $len = @$arr;

    $next = 0 unless defined $next;

    return $ITERATOR_CLASS->construct(
                                     name => 'iarray',

        reset => sub {
            $prev = $current = undef;
            $next = 0;
        },

        rewind => sub {
            $next = 0;
        },

        prev => sub {
            return defined $prev ? $arr->[$prev] : undef;
        },

        current => sub {
            return defined $current ? $arr->[$current] : undef;
        },

        next => sub {
            if ( $next == $len ) {
                # if first time through, set current/prev
                if ( !$_[0]->is_exhausted ) {
                    $prev    = $current;
                    $current = undef;
                    $_[0]->set_exhausted;
                }
                return undef;
            }
            $prev    = $current;
            $current = $next++;
            return $arr->[$current];
        },

        freeze => sub {
            return [ __PACKAGE__, '_iarray', [ $arr, $prev, $current, $next ] ];
        },

        exhausted => 'predicate',
    );
}


=sub icache

  $iterator = icache( $iterable );

The iterator caches the current and previous values of the passed iterator,

The returned iterator supports the following methods:

=over

=item reset

=item rewind

=item next

=item prev

=item current

=item freeze

=back

=cut

sub icache {
    _icache( iter( shift ), undef, undef );
}

sub _icache_thaw {
    my ( $src ) = @{ pop @_ };
    _icache( $src, @_ );
}

sub _icache {

    my ( $src, $prev, $current ) = @_;

    return $ITERATOR_CLASS->construct(

        reset => sub {
            $prev = $current = undef;
        },

        rewind => sub {
        },

        prev => sub {
            return $prev;
        },

        current => sub {
            return $current;
        },

        next => sub {

            return undef
              if $_[0]->is_exhausted;

            $prev    = $current;
            $current = $src->();

            $_[0]->set_exhausted
              if $src->is_exhausted;

            return $current;
        },

        freeze => sub {
            return [ __PACKAGE__, '_icache_thaw', [ $prev, $current ] ];
        },

        depends => $src,

        exhausted => 'predicate',
    );


}



=sub igrep

  $iterator = igrep { CODE } $iterable;

Returns an iterator equivalent to running L<grep> on C<$iterable> with the specified code.
C<CODE> is I<not> run if C<$iterable> returns I<undef> (that is, it is exhausted).

The iterator supports the following methods:

=over

=item next

=item reset

=back

=cut

sub igrep(&$) {

    my ( $code, $src ) = @_;
    $src = iter( $src );

    my %params = (
        name => 'igrep',
        next => sub {

            foreach ( ; ; ) {
                my $rv = $src->();
                last if $src->is_exhausted;
                local $_ = $rv;
                return $rv if $code->();
            }
            $_[0]->set_exhausted;
            return undef;
        },
        reset     => sub { },
        depends   => $src,
        exhausted => 'predicate',

    );

    $ITERATOR_CLASS->construct( %params );
}


=sub imap

  $iterator = imap { CODE } $iteraable;

Returns an iterator equivalent to running L<map> on C<$iterable> with the specified code.
C<CODE> is I<not> run if C<$iterable> returns I<undef> (that is, it is exhausted).

The iterator supports the following methods:

=over

=item next

=item reset

=back

=cut

sub imap(&$) {

    my ( $code, $src ) = @_;

    $src = iter( $src );

    $ITERATOR_CLASS->construct(
        next => sub {
            my $value = $src->();
            if ( $src->is_exhausted ) {
                $_[0]->set_exhausted;
                return undef;
            }
            local $_ = $value;
            return $code->();
        },
        reset     => sub { },
        depends   => $src,
        exhausted => 'predicate',
    );
}


=sub iproduct

  $iterator = iproduct( $iterable1, $iterable2, ... );
  $iterator = iproduct( key1 => $iterable1, key2 => iterable2, ... );

Returns an iterator which produces a Cartesian product of the input iterables.
If the input to B<iproduct> is a list of iterables, C<$iterator> will return an
array reference containing an element from each iterable.

If the input is a list of key, iterable pairs, C<$iterator> will return a
hash reference.

All of the iterables must support the C<rewind> method.

The iterator supports the following methods:

=over

=item current

=item next

=item reset

=item rewind

=item freeze

This iterator may be frozen only if all of the iterables support the
C<prev> or C<__prev__> method.

=back


=cut


sub iproduct {

    @_ = ( [@_] );
    goto \&_iproduct;
}

sub _iproduct {

    my ( $iterators, $value ) = @_;

    $value = [] unless defined $value;

    my @keys;
    my @iterator;

# distinguish between ( key => iterator, key =>iterator ) and ( iterator, iterator );
    if ( is_ref( $iterators->[0] ) ) {

        @iterator = map { iter( $_ ) } @$iterators;
    }

    else {
        @keys = pairkeys @$iterators;
        @iterator = map { iter( $_ ) } pairvalues @$iterators;
    }

    # can only work if the iterators support a rwind method
    croak( "iproduct requires that all iteratables provide a rewind method\n" )
      unless @iterator == grep { defined }
      map { $ITERATOR_CLASS->_can_meth( $_, 'rewind' ) } @iterator;

    my @value = @$value;
    my @set   = ( 1 ) x @value;

    my %params = (
        next => sub {
            return undef if $_[0]->is_exhausted;

            # first time through
            if ( !@value ) {

                for my $iter ( @iterator ) {
                    push @value, $iter->();

                    if ( $iter->is_exhausted ) {
                        $_[0]->set_exhausted;
                        return undef;
                    }
                }

                @set = ( 1 ) x @value;
            }

            else {

                $value[-1] = $iterator[-1]->();
                if ( $iterator[-1]->is_exhausted ) {
                    $set[-1] = 0;
                    my $idx = @iterator - 1;
                    while ( --$idx >= 0 ) {
                        $value[$idx] = $iterator[$idx]->();
                        last unless $iterator[$idx]->is_exhausted;
                        $set[$idx] = 0;
                    }

                    if ( !$set[0] ) {
                        $_[0]->set_exhausted;
                        return undef;
                    }

                    while ( ++$idx < @iterator ) {
                        $iterator[$idx]->rewind;
                        $value[$idx] = $iterator[$idx]->();
                        $set[$idx]   = 1;
                    }
                }

            }
            if ( @keys ) {
                my %value;
                @value{@keys} = @value;
                return \%value;
            }
            else {
                return [@value];
            }
        },

        current => sub {
            return undef if !@value || $_[0]->is_exhausted;
            if ( @keys ) {
                my %value;
                @value{@keys} = @value;
                return \%value;
            }
            else {
                return [@value];
            }
        },
        reset  => sub { @value = () },
        rewind => sub { @value = () },
        depends => \@iterator,
    );

    # can only freeze if the iterators support a prev method
    if (
        @iterator == grep { defined }
        map { $ITERATOR_CLASS->_can_meth( $_, 'current' ) } @iterator
      )
    {

        $params{freeze} = sub {
            return [ __PACKAGE__, '_iproduct_thaw', [ \@keys ] ];
          }
    }

    $ITERATOR_CLASS->construct( %params, exhausted => 'predicate', );
}

sub _iproduct_thaw {

    my ( $keys, $iterators ) = @_;
    my @value = map { $_->current } @$iterators;

    if ( @$keys ) {

        @$keys == @$iterators
          or croak(
            "iproduct thaw: number of keys not equal to number of iterators\n"
          );

        $iterators = [ map { $keys->[$_], $iterators->[$_] } 0 .. @$keys - 1 ];
    }

    _iproduct( $iterators, \@value );
}

=sub iseq

  # integer sequence starting at 0, incrementing by 1, ending at $end
  $iterator = iseq( $end );

  # integer sequence starting at $begin, incrementing by 1, ending at $end
  $iterator = iseq( $begin, $end );

  # real sequence starting at $begin, incrementing by $step, ending <= $end
  $iterator = iseq( $begin, $end, $step );

The iterator supports the following methods:

=over

=item current

=item next

=item prev

=item rewind

=item freeze

=back


=cut


sub iseq {
    splice( @_, 3 );
    push @_, ( undef ) x 3;
    goto \&_iseq;
}

sub _iseq {

    # these get pushed on as $prev, $current, $next, so pop in opposite
    # order
    my ( $next, $current, $prev ) = ( pop, pop, pop );

    croak( "iseq: arguments must be numbers\n" )
      if first { !looks_like_number( $_ ) } @_;

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
                    __PACKAGE__, '_iseq',
                    [ $begin, $end, $prev, $current, $next ] ];
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
                    __PACKAGE__, '_iseq',
                    [ $begin, $end, $step, $prev, $current, $next ] ];
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

    $ITERATOR_CLASS->construct(
        %params,
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

=sub ifreeze

  $iter = ifreeze { CODE } $iterator;

Construct a pass-through iterator which freezes the input iterator
after every call to C<next>.  C<CODE> will be passed the frozen state
(generated by calling C<$iterator->freeze> via C<$_>, with which it
can do as it pleases.

<CODE> I<is> executed when C<$iterator> returns I<undef> (that is,
when C<$iterator> is exhausted).

The returned iterator supports the following methods:

=over

=item next

=item prev

If C<$iterator> provides a C<prev> method.

=item rewind

=item freeze

=back


=cut

sub ifreeze (&$) {

    my $serialize = shift;
    my $src       = iter( shift );

    croak( "ifreeze requires that the iterator provide a freeze method\n" )
      unless $ITERATOR_CLASS->_can_meth( $src, 'freeze' );

    my %params = (
        rewind  => sub { },
        reset   => sub { },
        depends => $src,
        next    => sub {
            my $value = $src->();
            $_[0]->set_exhausted if $src->is_exhausted;
            local $_ = $src->freeze;
            &$serialize();
            $value;
        },
        exhausted => 'predicate',
    );

    for my $meth ( 'prev', 'current' ) {

        my $sub = $ITERATOR_CLASS->_can_meth( $src, $meth );

        $params{$meth} = sub { $src->$sub() }
          if defined $sub;
    }

    $ITERATOR_CLASS->construct( %params );
}


=sub thaw

   $frozen = $iterator->freeze;
   $iterator = thaw( $frozen );

Restore an iterator that has been frozen.  See L</Serialization of
Iterators> for more information.


=cut

sub thaw {

    my $step = shift;

    croak( "thaw: too many args\n" )
      if @_;

    my @steps = @$step;

    # parent data and iterator state is last
    my $state  = pop @steps;
    my $parent = pop @steps;

    my @depends = map { thaw( $_ ) } @steps;

    my ( $package, $funcname, $args ) = @$parent;

    require_module( $package );
    my $func = $package->can( $funcname )
      or croak( "unable to thaw: can't find $funcname in $package\n" );

    my @args
      = is_arrayref( $args ) ? @$args
      : is_hashref( $args )  ? %$args
      :                        $args;

    push @args, is_hashref( $args )
      ? ( depends => \@depends )
      : ( \@depends )
      if @depends;

    my $iter = &$func( @args );
    $iter->set_exhausted( $state );
    return $iter;
}

1;

# COPYRIGHT

__END__


=head1 SYNOPSIS

=head1 DESCRIPTION

C<Iterator::Flex> implements iterators with the following characteristics:

=over

=item I<next>

All iterators provide a C<next> method which advances the iterator and
returns the new value.

=item I<exhaustion>

Iterator exhaustion is signified by C<next> return C<undef>.

=item I<reset>

Iterators may optionally be rewound to their initial state

=item I<previous values>

Iterators may optionally return their previous value.

=item I<current>

Iterators return their current value.

=item I<freeze>

Iterators may optionally provide a C<freeze> method for serialization.
Iterators may be chained, and an iterator's dependencies are frozen automatically.

=back


=head1 SUBROUTINES

=head1 METHODS

Not all iterators support all methods.

=over

=item prev

  $value = $iter->prev;

Returns the previous value of the iterator.  If the iterator was never
advanced, this returns C<undef>.  If the iterator is exhausted, this
returns the last retrieved value. Use the L<state> method to determine
which state the iterator is in.

=item current

  $value = $iter->current;

Returns the current value of the iterator.  If the iterator was never
advanced, this returns undef.  If the iterator is exhausted, this
returns C<undef>.  Use the L<state> method to determine which state
the iterator is in.

=item next

  $value = $iter->next;

Return the next value from the iterator.

=item rewind

  $iter->rewind;

Resets the iterator so that the next value returned is the very first
value.  It should not affect the results of the L<prev> and L<current>
methods.

=item reset

  $iter->reset;

Resets the iterator to its initial state.  The iterator's state is not
changed.

=back


=head1 SEE ALSO
