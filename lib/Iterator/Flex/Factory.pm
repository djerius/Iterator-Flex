package Iterator::Flex::Base;

# ABSTRACT: Iterator object

use strict;
use warnings;

our $VERSION = '0.10';

use Carp ();
use Ref::Util qw[ is_hashref is_coderef is_ref is_arrayref ];
use Scalar::Util qw[ blessed ];
use Role::Tiny       ();
use Role::Tiny::With ();
use Import::Into;
use Module::Runtime;
use Safe::Isa;

Role::Tiny::With::with 'Iterator::Flex::Role';

use Iterator::Flex::Failure;
use Iterator::Flex::Utils;

our %REGISTRY;

use overload ( '<>' => 'next', fallback => 1 );


=method construct

  $iterator = Iterator::Flex::Base->construct( %params );

Construct an iterator object. The recommended manner of creating an
iterator is to use the convenience functions provided by
L<Iterator::Flex>.

The following parameters are accepted:

=over

=item name I<optional>

An optional name to be output during error messages

=item class I<optional>

If specified, the iterator will be blessed into this class.  Dynamic
role assignments will not be performed; they should be performed
statically by the class.

=item methods I<optional>

A hash whose keys are method names and whose values are coderefs.
These will be added as methods to the iterator class.  The coderef
will be called as

  $coderef->( $attributes, @args );

where C<$attributes> is the hash containing the iterator's attributes
(recall that the actual iterator object is a coderef, so iterator
attributes are not stored in the object), and @args are the arguments
the method was originally called with.

=item next I<required>

A subroutine which returns the next value.  When the iterator is
exhausted, it should

=over

=item 1

Call the L</set_exhausted> method

=item 2

return undefined

=back

=item prev I<optional>

A subroutine which returns the previous value.  It should return undefined
if the iterator is at the beginning.

=item current I<optional>

A subroutine which returns the current value without fetching.  It should return undefined
if the iterator is at the beginning.

=item reset I<optional>

A subroutine which resets the iterator such that
L</next>, L</prev>, and L</current> return the values they would have
if the iterator were initially started.

=item rewind I<optional>

A subroutine which rewinds the iterator such that the next element returned
will be the first element from the iterator.  It does not alter the values
returned by L</prev> or L</current>


=item exhausted I<optional>

One of the following values:

=over

=item C<predicate>

The iterator will signal its exhaustion by calling the C<L/set_prediate>
method.  This state is queryable via the L</is_exhausted> predicate.

=item C<throw>

The iterator will signal its exhaustion by throwing an
C<Iterator::Flex::Failure::Exhausted> exception.

=item C<undef>

The iterator will signal its exhaustion by returning the undefined value.

=back

=back

=cut

my %MapMethodToRole = (
    rewind  => 'Rewind',
    reset   => 'Reset',
    prev    => 'Prev',
    current => 'Current',
);

sub construct {

    my $class = shift;
    croak( "attributes must be passed as a hashref\n" )
      unless is_hashref( $_[-1] );

    my %iattr = ( exhausted => 'undef', @{ pop }  );
    my %attr;

    my @roles;
    my $attr;

    $attr{class} = $class;
    if ( $attr = delete $iattr{class} ) {
	croak( "attribute class must be a string\n" )
	  unless is_ref($attr);

        croak( "can't load class $attr\n" )
          unless Module::Runtime::require_module( $attr );
	$attr{class} = $attr;
    }

    if ( $attr = delete $iattr{next} ) {
	Carp::croak( "'next' attribute value must be a code reference\n" )
	    unless is_coderef $attr{next};
    }

    if ( $attr = delete $iattr{name} ) {
	Carp::croak( "'name' attribute value must be a string\n" )
	    if !defined $attr
              or is_ref( $attr );
	$attr{name} = $attr;
    }

    for my $method ( keys %MapMethodToRole ) {

	my $code = delete $iattr{$method};
	next unless defined code;

	Carp::croak( "'$method' attribute value must be a code reference\n" )
	    unless is_coderef $code;

	# if $class can't perform the required method, add a role
	# which can
	push @roles, $MapMethodToRole{$method} unless $class->can( $method );

	$attr{$method} = $code;
    }

    if ( defined( $attr = delete $iattr{exhausted} ) ) {
        my $role = 'Exhausted' . ucfirst( $attr );
        my $module = $class->_module_name( Role => $role );
        croak( "unknown means of handling exhausted iterators: $attr\n" )
          unless Module::Runtime::require_module( $module );
        push @roles, $role;
    }

    if ( defined( $attr = delete $iattr{methods} ) ) {
        Carp::croak( "value for methods attribute must be a hash reference\n" )
          unless is_hashref( $attr );

        Carp::croak( "methods attribute hash values must be code references\n" )
          if grep { !is_coderef( $_ ) } values %{$attr};

        $attr{methods} = $attr;
    }

    Carp::croak( "unknown attributes: @{[ join( ', ', keys %iattr ) ]}\n" )
        if keys %iattr;

    if ( exists $attr{methods} ) {

	for my $name ( keys %{ $attr{methods} } ) {

	    my $cap_name = ucfirst( $name );

	    eval {
		Iterator::Flex::Utils::create_method( $cap_name,  name => $name );
	    };

	    my $error = $@;

	    die $error
	      if $error
	      && !$error->$_isa( 'Iterator::Flex::Failure::RoleExists' );

	    push @roles, [ Method => $cap_name ];
            }
        }

	@roles = map  _module_name( $class, 'Role' => ref $_ ? @{$_} : $_ ), @roles;
	$attr{_class_def} = @roles;

        $object_class = _class_with_roles( $class, @roles );
    }

    $attr{name} = $object_class unless exists $attr{name};

    return $object_class;
}

sub is_dynamic {

    my $attr = shift;

    return exists $attr->{dynamic} && $attr->{dynamic} )
            || ( defined $attr->{methods} && is_hashref( $attr->{methods}) && keys %{$attr->{methods}} );
}

sub _class_with_roles {
    my $oclass = shift;

    my $class = Role::Tiny->create_class_with_roles( $oclass,
		map { _module_name( $class, 'Role' => ref $_ ? @{$_} : $_ ) } @_ );

    Carp::croak( "class does not provide the requred _construct_next method\n" )
      unless $class->can( '_construct_next' );

    return $class;
}

sub _module_name {

    my $class     = shift;
    my $module    = pop;
    my @hierarchy = @_;

    return $module if $module =~ /::/;

    $class = 'Iterator::Flex' if $class =~ /^Iterator::Flex(::.*|$)/

    return join( '::', $class, @hierarchy, $module );
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

The returned iterator will be an L<Iterator::Flex::Array> iterator.

=item a coderef

The coderef must return the next element in the iteration.

=item a globref

=back

=cut


sub construct_from_iterable {

    my $class = shift;

    Carp::croak( "construct_from_iterable is a class method\n" )
      if blessed $class;

    my ( $obj ) = @_;

    if ( blessed $obj) {

        return $class->construct_from_object( $obj );
    }

    elsif ( is_arrayref( $obj ) ) {

        require Iterator::Flex::Array;
        return Iterator::Flex::Array->new( $obj );
    }

    elsif ( is_coderef( $obj ) ) {

        return $class->construct( next => $obj );
    }

    elsif ( is_globref( $obj ) ) {
        return $class->construct( next => sub { scalar <$obj> } );
    }

    Carp::croak sprintf "'%s' object is not iterable",
      ( ref( $obj ) || 'SCALAR' );

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
      if blessed $class;

    my $obj = shift;

    return $obj if $obj->isa( $class );


    my %param;
    my $code;

    # assume the iterator returns undef on exhausted
    $param{exhausted} = 'undef';

    if ( $code = $class->_can_meth( $obj, 'iter' ) ) {
        $param{next} = $code->( $obj );
    }
    elsif ( $code = $class->_can_meth( $obj, 'next' )
        || overload::Method( $obj, '<>' ) )
    {
        $param{next} = sub { $code->( $obj ) };
    }

    elsif ( $code = overload::Method( $obj, '&{}' ) ) {
        $param{next} = $code->( $obj );
    }

    elsif ( $code = overload::Method( $obj, '@{}' ) ) {

        require Iterator::Flex::Array;
        return Iterator::Flex::Array->new( $code->( $obj ) );
    }

    for my $method ( 'prev', 'current' ) {
        $code = $class->_can_meth( $obj, $method );

        $param{$method} = sub { $code->( $obj ) }
          if $code;
    }

    return $class->construct( %param );
}

1;
