package Iterator::Flex::Iterator;

# ABSTRACT: Iterator object

use strict;
use warnings;

our $VERSION = '0.02';

use Carp ();
use Ref::Util;
use Scalar::Util;
use Role::Tiny ();

use overload (
    '<>'     => 'next',
    '&{}'    => sub { $_[0]->{next} },
    fallback => 1,
);

=method new

  $iterator = Iterator::Flex::Iterator->new( %params );

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

sub new {

    my $class = shift;
    my %attr = @_ ;

    for my $key ( keys %attr ) {

        if ( $key =~ /^(next|prev|rewind|freeze)$/ ) {
            Carp::croak( "value for $_ attribute must be a code reference\n" )
                unless Ref::Util::is_coderef  $attr{$key};
        }
        elsif ( $key eq 'depends' ) {

            $attr{$key} = [ $attr{$key} ] unless Ref::Util::is_arrayref( $attr{$key} );
            my $depends = $attr{$key};

            Carp::croak( "dependency #$_ is not an iterator object\n" )
              for grep { ! ( Scalar::Util::blessed( $depends->[$_] ) && $depends->[$_]->isa( $class ) ) } 0..$#{$depends};
        }
        elsif ( $key eq 'name' ) {
            Carp::croak( "$_ must be a string\n" )
              if ! defined $attr{$key} or Ref::Util::is_ref($attr{$key});
        }
        else {
            Carp::croak( "unknown attribute: $key\n" )
          }
    }

    my @roles;
    push @roles, 'Rewind' if exists $attr{rewind};
    push @roles, 'Previous' if exists $attr{prev};
    push @roles, 'Serialize' if exists $attr{freeze};

    my $composed_class = Role::Tiny->create_class_with_roles( $class, map { "$class::$_" } @roles );

    $attr{name} = $composed_class unless exists $attr{name};

    my $obj = bless \%attr, $composed_class;
}


=method next

=method __next__

  $value = $iter->next;

Return the next value from the iterator.  Returns C<undef> if the
iterator is exhausted.

=cut


sub next { goto $_[0]->{next} }
*__next__ = \&next;

=method __iter__

   $sub = $iter->__iter__;

Returns the subroutine which returns the next value from the iterator.

=cut

sub __iter__ { $_[0]->{next} }

1;

