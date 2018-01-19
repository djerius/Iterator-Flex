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
use Module::Runtime;

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
    my %attr = ( exhausted => 'undef', @_ );

    my @roles;

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
        elsif ( $key eq 'exhausted' ) {

            my $role = 'Exhausted' . ucfirst( $attr{$key} );
            my $module
              = $attr{$key} =~ /::/
              ? $attr{$key}
              : join( '::', $class, 'Role', $role );
            croak(
                "unknown means of handling exhausted iterators: $attr{$key}\n" )
              unless Module::Runtime::require_module( $module );
            push @roles, $role;
        }
        else {
            Carp::croak( "unknown attribute: $key\n" );
        }
    }


    push @roles, 'Rewind'    if exists $attr{rewind};
    push @roles, 'Reset'     if exists $attr{reset};
    push @roles, 'Previous'  if exists $attr{prev};
    push @roles, 'Current'   if exists $attr{current};
    push @roles, 'Serialize' if exists $attr{freeze};

    my $composed_class = Role::Tiny->create_class_with_roles( $class,
        map { join( '::', $class, 'Role', $_ ) } @roles );


    # this slows down the class, even if the overload is never used.
    overload->import::into( $composed_class,
        '&{}' => sub { $_[0]->{_overload_next} } );

    $attr{name} = $composed_class unless exists $attr{name};

    my $obj = bless \%attr, $composed_class;
    $obj->{is_exhausted} = 0;

    my $next = $composed_class->can( 'next' );
    $obj->{_overload_next} = sub { $next->( $obj ) };

    if ( defined $attr{init} ) {
        local $_ = $obj;
        $attr{init}->();
        delete $attr{init};
    }

    return $obj;
}

sub DESTROY {
    delete $_[0]->{_overload_next}
      if defined $_[0];
}


=method set_exhausted

  $iter->set_exhausted;

Set the iterator's state to exhausted

=cut

sub set_exhausted { $_[0]->{is_exhausted} = defined $_[1] ? $_[1] : 1 }


=method is_exhausted

  $bool = $iter->is_exhausted;

Returns true if the iterator is exhausted and there are no more values
available.  L<current> and L<next> will return C<undef>.  L<prev> will
return the last valid value returned by L<next>.

L<is_exhausted> is true only after L<next> has been called I<after>
the last valid value has been returned by a previous call to
L<next>. In other words, if C<$iter->next> returns the last valid
value, the state is still I<active>.  The next call to C<$iter->next>
will switch the iterator state to I<exhausted>.


=cut

sub is_exhausted { $_[0]->{is_exhausted} }

=method __iter__

   $sub = $iter->__iter__;

Returns the subroutine which returns the next value from the iterator.

=cut

sub __iter__ { $_[0]->{next} }

1;

