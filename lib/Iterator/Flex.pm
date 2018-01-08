package Iterator::Flex;

# ABSTRACT: Iterators which can be rewound and serialized

use strict;
use warnings;

our $VERSION = '0.02';

use Exporter 'import';

our @EXPORT_OK = qw[ iterator iter iarray igrep imap iproduct iseq ifreeze thaw ];

use Carp;
use Scalar::Util qw[ blessed looks_like_number ];
use Ref::Util qw[ is_coderef is_arrayref is_hashref is_ref ];
use Module::Runtime qw[ require_module ];
use List::Util qw[ pairkeys pairvalues all first ];

## no critic ( ProhibitExplicitReturnUndef ProhibitSubroutinePrototypes)

use Iterator::Flex::Iterator;

use constant ITERATOR_CLASS => __PACKAGE__ . '::Iterator';


sub _can_freeze {

    return _can_meth( $_[0], qw[ __freeze__ freeze ] );
}

sub _can_prev {

    return _can_meth( $_[0], qw[ __prev__ prev previous ] );
}

sub _can_rewind {

    return _can_meth( $_[0], qw[ __rewind__ rewind ] );
}

sub _can_meth {

    my $obj = shift;

    my $sub;
    foreach ( @_ )  {

        last if defined ($sub = $obj->can( $_ ));
    }

    return $sub;
}

=sub iterator


=cut
sub iterator(&) {
    ITERATOR_CLASS->new( next => $_[0] );
}


=sub iter

  $iter = iter( $object );

Transform C<$object> into an iterator.  It accepts

=cut

sub iter {

    return iterator { return }
    unless @_;

    my ( $self ) = @_;

    if ( blessed $self) {

        return $self if $self->isa( ITERATOR_CLASS );

        my $method;

        if ( $method = $self->can( '__iter__' ) ) {
            return $method->( $self );
        }

        elsif ( $method
            = overload::Method( $self, '<>' ) || $self->can( 'next' ) )
        {

            return ITERATOR_CLASS->new( next => sub { $method->( $self ) } );
        }

        elsif ( $method = overload::Method( $self, '&{}' ) ) {

            return ITERATOR_CLASS->new( next => $method->( $self ) );
        }

        elsif ( $method = overload::Method( $self, '@{}' ) ) {

            return iarray( $method->( $self ) );
        }
    }

    elsif ( is_arrayref( $self ) ) {

        return iarray( $self );
    }

    elsif ( is_coderef( $self ) ) {

        return ITERATOR_CLASS->new( next => $self );
    }

    elsif ( is_globref( $self ) ) {
        return ITERATOR_CLASS->new( next => sub { scalar <$self> } );
    }

    croak sprintf "'%s' object is not iterable", ( ref( $self ) || 'SCALAR' );
}


=sub iarray

  $iterator = iarray( $array_ref );

Wrap an array in an iterator.

The returned iterator supports the following methods:

=over

=item next

=item prev

=item rewind

=item freeze

=back

=cut

sub iarray {
    return _iarray( $_[0] );
}

sub _iarray {

    my ( $arr, $idx ) = @_;

    croak 'Argument to iarray must be ARRAY reference'
      unless is_arrayref( $arr );

    $idx = 0 unless defined $idx;

    return ITERATOR_CLASS->new(
        rewind => sub { $idx = 0 },
        next => sub {
            return undef if $idx == @$arr;
            return $arr->[ $idx++ ];
        },
        freeze => sub {
            return [ __PACKAGE__, '_iarray', [ $arr, $idx ] ];
        },

        prev => sub {
            return undef if $idx == 0;
            return $arr->[ $idx - 1 ];
        },
    );
}


# =sub icache

#   $iterator = cache( $iterable, ?$cache_size );

# Returns a caching iterator.  The iterator will cache C<$cache_size>
# values (defaults to 1) from C<$iterable>.

# The returned iterator supports the following methods:

# =over

# =item rewind

# =item next

# =item prev

# =back


=sub igrep

  $iterator = igrep { CODE } $iterable;

Returns an iterator equivalent to running L<grep> on C<$iterable> with the specified code.
C<CODE> is I<not> run if C<$iterable> returns I<undef> (that is, it is exhausted).

The iterator supports the following methods:

=over

=item next

=item rewind

=back

=cut

sub igrep(&$) {

    my ( $code, $src ) = @_;
    $src = iter( $src );

    my %params = (
        next => sub {
            while ( defined( my $rv = $src->() ) ) {
                local $_ = $rv;
                return $rv if $code->();
            }
            return;
        },
        rewind  => sub { },
        depends => $src,
    );

    ITERATOR_CLASS->new( %params );
}


=sub imap

  $iterator = imap { CODE } $iteraable;

Returns an iterator equivalent to running L<map> on C<$iterable> with the specified code.
C<CODE> is I<not> run if C<$iterable> returns I<undef> (that is, it is exhausted).

The iterator supports the following methods:

=over

=item next

=item rewind

=back

=cut

sub imap(&$) {

    my ( $code, $src ) = @_;

    $src = iter( $src );

    ITERATOR_CLASS->new(
        next => sub {
            local $_ = $src->next;
            return if not defined $_;
            return $code->();
        },
        rewind  => sub { },
        depends => $src,
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

=item next

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
      unless @iterator == grep { defined } map { _can_rewind( $_ ) } @iterator;

    my @value = @$value;

    my %params = (
        next => sub {
            # first time through
            if ( !@value ) {
                @value = map { $_->next } @iterator;
            }

            elsif ( !defined( $value[0] ) ) {
                return;
            }

            elsif ( !defined( $value[-1] = $iterator[-1]->next ) ) {

                my $idx = @iterator - 1;
                1 while --$idx >= 0
                  && !defined( $value[$idx] = $iterator[$idx]->next );

                return if !defined $value[0];

                while ( ++$idx < @iterator ) {
                    $iterator[$idx]->rewind;
                    $value[$idx] = $iterator[$idx]->next;
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

        rewind => sub { @value = () },
        depends => \@iterator,
    );

    # can only freeze if the iterators support a prev method
    if ( @iterator == grep { defined } map { _can_prev( $_ ) } @iterator ) {

        $params{freeze} = sub {
            return [ __PACKAGE__, '_iproduct_thaw', [ \@keys ] ];
          }
    }

    ITERATOR_CLASS->new( %params );
}

sub _iproduct_thaw {

    my ( $keys, $iterators ) = @_;
    my @value = map { $_->prev } @$iterators;

    if ( @$keys ) {
        my %iterators;
        @iterators{@$keys} = @$iterators;
        $iterators = \%iterators;
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

=item next

=item prev

=item rewind

=item freeze

=back


=cut


sub iseq {
    splice( @_, 3 );
    push @_, undef, undef;
    goto \&_iseq;
}

sub _iseq {

    # these get pushed on as $prev, $next, so pop in opposite
    # order
    my ( $next, $prev ) = ( pop, pop );

    croak( "iseq: arguments must be numbers\n" )
      if first { !looks_like_number( $_ ) } @_;

    my %params;

    if ( @_ == 1 ) {

        my ( $end ) = @_;

        $next = 0 unless defined $next;

        %params = (
            next => sub {
                return undef if $next > $end;
                $prev = $next++;
                return $prev;
            },
            rewind => sub {
                $prev = undef;
                $next = 0;
            },
            freeze => sub {
                [ __PACKAGE__, '_iseq', [ $end, $prev, $next ] ];
            } );
    }

    elsif ( @_ == 2 ) {

        my ( $begin, $end ) = @_;

        $next = $begin unless defined $next;

        %params = (
            next => sub {
                return undef if $next > $end;
                $prev = $next++;
                return $prev;
            },
            rewind => sub {
                $prev = undef;
                $next = $begin;
            },
            freeze => sub {
                [ __PACKAGE__, '_iseq', [ $begin, $end, $prev, $next ] ];
            },
        );
    }

    else {

        my ( $begin, $end, $step ) = @_;

        croak(
            "sequence will be inifinite as \$step is zero or has the incorrect sign\n"
          )
          if ( $begin < $end && $step <= 0 ) || ( $begin > $end && $step >= 0 );

        $next = $begin unless defined $next;

        %params = (
            rewind => sub {
                $prev = undef;
                $next = $begin;
            },

            freeze => sub {
                [ __PACKAGE__, '_iseq', [ $begin, $end, $step, $prev, $next ] ];
            },

            next => $begin < $end
            ? sub {
                return undef if $next > $end;
                $prev = $next;
                $next += $step;
                return $prev;
            }
            : sub {
                return undef if $next < $end;
                $prev = $next;
                $next += $step;
                return $prev;
            },
        );
    }

    $params{prev} = sub { $prev };

    ITERATOR_CLASS->new( %params );
}

=sub ifreeze

  $iter = ifreeze { CODE } $iterator;

Freeze an iterator after every call to C<next>.  C<CODE> will be
passed a frozen state (generated by calling C<$iterator->freeze> via
C<$_>, with which it can do as it pleases.

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
    my $iter      = iter( shift );

    croak( "ifreeze requires that the iterator provide a freeze method\n" )
      unless _can_freeze( $iter );

    my %params = (
        rewind  => sub { },
        depends => $iter,
        next    => sub {
            my $value = $iter->next;
            local $_ = $iter->freeze;
            &$serialize();
            $value;
        } );

    if ( defined( my $sub = _can_prev( $iter ) ) ) {
        $params{prev} = sub { $iter->$sub() };
    }

    ITERATOR_CLASS->new( %params );
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

    # parent data is last
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

    return &$func( @args );
}

1;

# COPYRIGHT

__END__


=head1 SYNOPSIS


=head1 SEE ALSO
