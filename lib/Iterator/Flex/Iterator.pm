package Iterator::Flex::Iterator;

# ABSTRACT: Iterator object

use strict;
use warnings;

our $VERSION = '0.04';

use Carp ();
use Ref::Util;
use Scalar::Util;
use Role::Tiny ();
use Import::Into;

use Iterator::Flex::Constants;
use Iterator::Flex::Failure;

use overload ( '<>' => 'next' );

=method construct

  $iterator = Iterator::Flex::Iterator->construct( %params );

Construct an iterator object. The recommended manner of creating an
iterator is to use the convenience functions provided by
L<Iterator::Flex>.

The following parameters are accepted:

=over

=item next I<required>

A subroutine which returns the next value.  It should return undefined
if the iterator is exhausted.

=item prev I<optional>

A subroutine which returns the previous value.  It should return undefined
if the iterator is at the beginning.

=item rewind I<optional>

A subroutine which resets the iterator to its initial value.

=item freeze I<optional>

A subroutine which returns an array reference with the following elements, in the specified order :

=over

=item 1

The name of the package containing the thaw subroutine.

=item 2

The name of the thaw subroutine.

=item 3

The data to be passed to the thaw routine.  The routine will be called
as:

  thaw( @{$data}, ?$depends );

if C<$data> is an arrayref,

  thaw( %{$data}, ?( depends => $depends )  );

if C<$data> is a hashref, or

  thaw( $data, ?$depends );

for any other type of data.

Dependencies are passed to the thaw routine only if they are present.


=back

=back

=cut

sub construct {

    my $class = shift;
    my %attr = ( throw => 0, @_ );

    for my $key ( keys %attr ) {

        if ( $key =~ /^(init|next|prev|rewind|reset|freeze|current)$/ ) {
            Carp::croak( "value for $_ attribute must be a code reference\n" )
              unless Ref::Util::is_coderef $attr{$key};
        }
        elsif ( $key eq 'depends' ) {

            $attr{$key} = [ $attr{$key} ]
              unless Ref::Util::is_arrayref( $attr{$key} );
            my $depends = $attr{$key};

            Carp::croak( "dependency #$_ is not an iterator object\n" )
              for grep {
                !( Scalar::Util::blessed( $depends->[$_] )
                    && $depends->[$_]->isa( $class ) )
              } 0 .. $#{$depends};
        }
        elsif ( $key eq 'name' ) {
            Carp::croak( "$_ must be a string\n" )
              if !defined $attr{$key}
              or Ref::Util::is_ref( $attr{$key} );
        }
        elsif ( $key eq 'throw' ) {
        }
        else {
            Carp::croak( "unknown attribute: $key\n" );
        }
    }


    my @roles;
    push @roles, $attr{throw} ? 'ExhaustedThrow' : 'ExhaustedUndef';
    push @roles, 'Rewind'    if exists $attr{rewind};
    push @roles, 'Reset'     if exists $attr{reset};
    push @roles, 'Previous'  if exists $attr{prev};
    push @roles, 'Current'   if exists $attr{current};
    push @roles, 'Serialize' if exists $attr{freeze};

    my $composed_class = Role::Tiny->create_class_with_roles( $class,
        map { join( '::', $class, 'Role', $_ ) } @roles );

    my $next = $composed_class->can( 'next' );

    # this slows down the class, even if the overload is never used.
    # also, it generates a new sub every time the overload is invoked.
    overload->import::into(
        $composed_class,
        '&{}' => sub {
            my $self = shift;
            sub { $next->( $self ) }
        } );

    $attr{name} = $composed_class unless exists $attr{name};

    my $obj = bless \%attr, $composed_class;
    $obj->{state} = Iterator::Flex::Constants::INACTIVE;

    if ( defined $attr{init} ) {
        local $_ = $obj;
        $attr{init}->();
        delete $attr{init};
    }

    return $obj;
}


=method set_exhausted

  $iter->set_exhausted;

Set the iterator's state to C<Iterator::Flex::Constants::EXHAUSTED>.

=cut

sub set_exhausted { $_[0]->_set_state( Iterator::Flex::Constants::EXHAUSTED )  }


=method is_exhausted

  $bool = $iter->is_exhausted;

Returns true if the iterator is exhausted

=cut

sub is_exhausted { $_[0]->state eq Iterator::Flex::Constants::EXHAUSTED }

=method is_inactive

  $bool = $iter->is_inactive;

Returns true if the iterator is inactive

=cut

sub is_inactive { $_[0]->state eq Iterator::Flex::Constants::INACTIVE }

=method is_active

  $bool = $iter->is_active;

Returns true if the iterator is active.

=cut

sub is_active { $_[0]->state eq Iterator::Flex::Constants::ACTIVE }


=method state

  $bool = $iter->state;

Returns the state of the iterator.  It is one of

=over

=item Iterator::Flex::Constants::INACTIVE

=item Iterator::Flex::Constants::ACTIVE

=item Iterator::Flex::Constants::EXHAUSTED

=back

=cut

sub state {  $_[0]->{state} };

sub _set_state {
    my $self = shift;
    $self->{state} = shift if @_;
    return $self->{state};
}

=method __iter__

   $sub = $iter->__iter__;

Returns the subroutine which returns the next value from the iterator.

=cut

sub __iter__ { $_[0]->{next} }

1;

