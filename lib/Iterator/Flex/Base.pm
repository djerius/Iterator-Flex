package Iterator::Flex::Base;

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

our %REGISTRY;

use overload ( '<>' => 'next', fallback => 1 );

=method construct

  $iterator = Iterator::Flex::Base->construct( %params );

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
    Carp::croak( "construct is a class method\n" )
        if Scalar::Util::blessed $class;

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
        elsif ( $key =~ /name|class/ ) {
            Carp::croak( "$_ must be a string\n" )
              if !defined $attr{$key}
              or Ref::Util::is_ref( $attr{$key} );
        }
        elsif ( $key eq 'exhausted' ) {

            my $role = 'Exhausted' . ucfirst( $attr{$key} );
            my $module = $class->_module_name( Role => $role );
            croak(
                "unknown means of handling exhausted iterators: $attr{$key}\n" )
              unless Module::Runtime::require_module( $module );
            push @roles, $role;
        }
        else {
            Carp::croak( "unknown attribute: $key\n" );
        }
    }

    my $composed_class;

    if ( defined $attr{class} ) {
        $composed_class = $class->_module_name( $attr{class} );
        Module::Runtime::require_module( $composed_class );
    }

    else {

        push @roles, 'Rewind'    if exists $attr{rewind};
        push @roles, 'Reset'     if exists $attr{reset};
        push @roles, 'Previous'  if exists $attr{prev};
        push @roles, 'Current'   if exists $attr{current};
        push @roles, 'Serialize' if exists $attr{freeze};

        $composed_class = Role::Tiny->create_class_with_roles( $class, map { $class->_module_name( 'Role' => $_ ) } @roles );
    }


    $attr{name} = $composed_class unless exists $attr{name};
    $attr{is_exhausted} = 0;

    my $obj = bless $composed_class->_construct_next( \%attr ), $composed_class;

    $REGISTRY{ Scalar::Util::refaddr $obj } = \%attr;
    # my $next = $composed_class->can( 'next' );
    # $attr{_overload_next} = sub { $next->( $obj ) };

    if ( defined $attr{init} ) {
        $attr{init}->( $obj );
        delete $attr{init};
    }

    return $obj;
}

sub _module_name {

    my $class = shift;
    my $module = pop;
    my @hierarchy = @_;

    return $module if $module  =~ /::/;

    $class = 'Iterator::Flex' if $class eq __PACKAGE__;

    return join( '::', $class, @hierarchy, $module );
}


sub _add_roles {

    my $class = shift;

    Role::Tiny->apply_roles_to_package( $class, map { "Iterator::Flex::Role::$_" } @_ );
}

=method construct_from_iterable

  $iter = Iterator::Flex::Base->construct_from_iterable( $iterable );

Construct an iterator from an iterable thing.  The returned iterator will
return C<undef> upon exhaustion.

An iterable thing is

=over

=item an object with certain methods

See L</construct_from_object>

=item an arrayref

The returned iterator will be an L<Iterator::Flex/iarray> iterator.

=item a coderef

The coderef must return the next element in the iteration.

=item a globref

=back

=cut


sub construct_from_iterable {

    my $class = shift;

    Carp::croak( "construct_from_iterable is a class method\n" )
        if Scalar::Util::blessed $class;

    my ( $obj ) = @_;

    if ( Scalar::Util::blessed $obj) {

        return $class->construct_from_object( $obj );
    }

    elsif ( Ref::Util::is_arrayref( $obj ) ) {

        return Iterator::Flex::iarray( $obj );
    }

    elsif ( Ref::Util::is_coderef( $obj ) ) {

        return $class->construct( next => $obj );
    }

    elsif ( is_globref( $obj ) ) {
        return $class->construct( next => sub { scalar <$obj> } );
    }

    Carp::croak sprintf "'%s' object is not iterable", ( ref( $obj ) || 'SCALAR' );

}

=method construct_from_object

  $iter = Iterator::Flex::Base->construct_from_object( $iterable );

Construct an iterator from an object.  Normal use is to call L<construct_from_iterable> or
simply use L<Iterator::Flex/iter>.  The returned iterator will return C<undef> upon exhaustion.


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

=cut


sub construct_from_object {

    my $class = shift;

    Carp::croak( "construct_from_object is a class method\n" )
        if Scalar::Util::blessed $class;


    my $obj   = shift;

    return $obj if $obj->isa( $class );


    my %param;
    my $code;

    # assume the iterator returns undef on exhausted
    $param{exhausted} = 'undef';

    if ( $code = $class->_can_meth( $obj, 'iter' ) ) {
        $param{next} = $code->( $obj );
    }
    elsif ( $code = $class->_can_meth( $obj, 'next' ) || overload::Method( $obj, '<>' ) ) {
        $param{next} = sub { $code->( $obj ) };
    }

    elsif ( $code = overload::Method( $obj, '&{}' ) ) {
          $param{next} = $code->( $obj );
    }

    elsif ( $code = overload::Method( $obj, '@{}' ) ) {

          return Iterator::Flex::iarray( $code->( $obj ) );
    }

    for my $method ( 'prev', 'current' ) {
        $code = $class->_can_meth( $obj, $method );

        $param{$method} = sub { $code->( $obj ) }
          if $code;
    }

    return $class->construct( %param );
}


sub DESTROY {

    if ( defined $_[0] ) {
        my $self = delete $REGISTRY{ Scalar::Util::refaddr $_[0] };
        delete $self->{_overload_next}
    }

}

sub _can_meth {

    my $class = shift;
    my ( $obj, $meth ) = @_;

    my $sub;
    foreach ( "__${meth}__", $meth ) {

        last if defined( $sub = $obj->can( $_ ) );
    }

    return $sub;
}


=method set_exhausted

  $iter->set_exhausted;

Set the iterator's state to exhausted

=cut

sub set_exhausted {
    my $self = $REGISTRY{ Scalar::Util::refaddr $_[0] };
    $self->{is_exhausted} = defined $_[1] ? $_[1] : 1
}


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

sub is_exhausted {
    my $self = $REGISTRY{ Scalar::Util::refaddr $_[0] };
    $self->{is_exhausted};
}

=method __iter__

   $sub = $iter->__iter__;

Returns the subroutine which returns the next value from the iterator.

=cut

sub __iter__ {
    my $self = $REGISTRY{ Scalar::Util::refaddr $_[0] };
    $self->{next};
}

1;
