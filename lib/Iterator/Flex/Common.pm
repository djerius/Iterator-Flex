package Iterator::Flex::Common;

# ABSTRACT: Iterator Generators and Adapters

use 5.10.0;
use strict;
use warnings;

use experimental 'postderef';

our $VERSION = '0.12';

use Exporter 'import';

our @EXPORT_OK
  = qw[ iterator iter iarray icycle icache igrep imap iproduct iseq ifreeze thaw ];
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Ref::Util qw[ is_arrayref is_hashref is_ref is_globref ];
use Module::Runtime qw[ require_module ];

sub _throw {
    require Iterator::Flex::Failure;
    my $type  = join( '::', 'Iterator::Flex::Failure', shift );
    $type->throw( { msg => shift, trace => Iterator::Flex::Failure->croak_trace } );
}


=begin internals

=sub _parse_params

     \%pars = _parse_params( \@_ );

Scans the passed arrayref for trailing C<< -pars => \%pars >> entries.  If found,
removes them from the passed array and returns C<\%pars>.

=end internals

=cut


sub _parse_params {
    my ( $args ) = @_;

    my $pars = {};
    # look for a -pars => \%pars at the end of the argument list
    if (   $args->@* > 2
        && is_hashref( $args->[-1] )
        && !( is_ref( $args->[-2] ) || is_globref( \( $args->[-2] ) ) )
        && $args->[-2] eq '-pars' )
    {
        $pars = pop $args->@*;
        # get rid of '-pars'
        pop $args->@*;
    }

    return $pars;
}

=sub iterator

  $iter = iterator { CODE } ?\%params;

Construct an iterator from code. The code will have access to the
iterator object through C<$_[0]>. By default the code is expected to
return C<undef> upon exhaustion.

For example, here's a simple integer sequence iterator that counts up to 100:

# EXAMPLE: ./examples/Common/iterator.pl

See L</General Options> for a description of C<%params>

=cut

sub iterator(&@) {
    my $pars = _parse_params( \@_ );
    @_ >1 && _throw( parameter => 'extra_argument' );
    require Iterator::Flex::Factory;
    Iterator::Flex::Factory->construct_from_iterable( $_[0], $pars );
}


=sub iter

  $iter = iter( $iterable, ?\%params );

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
    my $pars = _parse_params( \@_ );
    @_ > 1 && _throw( parameter => 'extra_argument' );
    require Iterator::Flex::Factory;
    Iterator::Flex::Factory->to_iterator( $_[0], $pars );
}


=sub iarray

  $iterator = iarray( $array_ref, ?\%params );

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
    my $pars = _parse_params( \@_ );
    @_ > 1 && _throw( parameter => 'extra_argument' );
    require Iterator::Flex::Array;
    return Iterator::Flex::Array->new( $_[0], $pars );
}

=sub icache

  $iterator = icache( $iterable, ?\%params );

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
    my $pars = _parse_params( \@_ );
    @_ > 1 && _throw( parameter => 'extra_argument' );
    require Iterator::Flex::Cache;
    Iterator::Flex::Cache->new( $_[0], $pars );
}

=sub icycle

  $iterator = icycle( $array_ref, ?\%params );

Wrap an array in an iterator.  The iterator will continuously cycle through the array's values.

=over

=item current

=item next

=item prev

=item rewind

=item reset

=item freeze

=back

=cut

sub icycle {
    my $pars = _parse_params( \@_ );
    @_ > 1 && _throw( parameter => 'extra_argument' );
    require Iterator::Flex::Cycle;
    return Iterator::Flex::Cycle->new( $_[0], $pars );
}


=sub igrep

  $iterator = igrep { CODE } $iterable, ?\%params;

Returns an iterator equivalent to running L<grep> on C<$iterable> with the specified code.
C<CODE> is I<not> run if C<$iterable> returns I<undef> (that is, it is exhausted).

The iterator supports the following methods:

=over

=item next

=item reset

=back

=cut

sub igrep(&$) {
    my $pars = _parse_params( \@_ );
    @_ > 2 && _throw( parameter => 'extra_argument' );
    require Iterator::Flex::Grep;
    Iterator::Flex::Grep->new( @_, $pars );
}


=sub imap

  $iterator = imap { CODE } $iterable, ?\%params;

Returns an iterator equivalent to running L<map> on C<$iterable> with the specified code.
C<CODE> is I<not> run if C<$iterable> returns I<undef> (that is, it is exhausted).

The iterator supports the following methods:

=over

=item next

=item reset

=back

=cut

sub imap(&$) {
    my $pars = _parse_params( \@_ );
    @_ > 2 && _throw( parameter => 'extra_argument' );
    require Iterator::Flex::Map;
    Iterator::Flex::Map->new( @_, $pars );
}


=sub iproduct

  $iterator = iproduct( $iterable1, $iterable2, ..., ?\%params );
  $iterator = iproduct( key1 => $iterable1, key2 => iterable2, ..., ?\%params );

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
    my $pars = _parse_params( \@_ );
    require Iterator::Flex::Product;
    return Iterator::Flex::Product->new( @_, $pars );
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
    my $pars = _parse_params( \@_ );
    require Iterator::Flex::Sequence;
    Iterator::Flex::Sequence->new( @_, $pars );
}


=sub ifreeze

  $iter = ifreeze { CODE } $iterator, ?\%params;

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
    my $pars = _parse_params( \@_ );
    @_ > 2 && _throw( parameter => 'extra_argument' );
    require Iterator::Flex::Freeze;
    Iterator::Flex::Freeze->new( @_, $pars );
}


=sub thaw

   $frozen = $iterator->freeze;
   $iterator = thaw( $frozen, ?\%params );

Restore an iterator that has been frozen.  See L</Serialization of
Iterators> for more information.


=cut

sub thaw {
    my $pars = _parse_params( \@_ );
    @_ > 1 && _throw( parameter => 'extra_argument' );

    my @steps = @{$_[0]};

    # parent data and iterator state is last
    my $exhausted = pop @steps;
    my $parent    = pop @steps;

    my @depends = map { thaw( $_ ) } @steps;

    my ( $package, $state ) = @$parent;

    _throw( parameter => "state argument for $package constructor must be a HASH  reference" )
      unless is_hashref( $state );

    require_module( $package );
    my $new_from_state = $package->can( 'new_from_state' )
      or
    _throw( parameter => "unable to thaw: $package doesn't provide 'new_from_state' method" );

    $state->{depends} = \@depends
      if @depends;

    $state->{thaw} = 1;

    my $iter = $package->$new_from_state( $state, $pars );
    $exhausted ? $iter->set_exhausted : $iter->_clear_state;
    return $iter;
}

1;

# COPYRIGHT

__END__


=head1 SYNOPSIS

=head1 DESCRIPTION

C<Iterator::Flex::Common> provides generators for iterators for some
common cases (arrays, sequences), arbitrary code, and iterator
adaptors.  As described in
L<Iterator::Flex::Manual::Overview/Capabilities>, iterators have
optional capabilities; the descriptions below list which capabilities
each iterator provides.

=head2 General Options

Most of the generators take an optional trailing options hash. To pass
extra general iterator options, use the C<-pars> options.  For
example, to indicate that you'd like the iterator to throw an
exception when exhausted, instead of returning C<undef>, set

  %params = ( -pars => { exhaustion => 'throw' } );

  $iter = iarray( \@array, \%params );

