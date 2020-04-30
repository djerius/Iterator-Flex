package Iterator::Flex::Factory;

# ABSTRACT: Create on-the-fly Iterator::Flex classes/objects

use strict;
use warnings;

our $VERSION = '0.11';

use Ref::Util qw[ is_hashref is_coderef is_ref is_arrayref ];
use Scalar::Util qw[ blessed ];
use Role::Tiny       ();
use Role::Tiny::With ();
use Module::Runtime;
use Safe::Isa;

use Iterator::Flex::Base;
use Iterator::Flex::Failure;
use Iterator::Flex::Utils qw[ _croak _can_meth
                              :NativeExhaustionActions
                              :RequestedExhaustionActions
                           ];
use Iterator::Flex::Method;

=sub to_iterator

  $iter = Iterator::Flex::Factory::to_iterator( $iterable, %attributes );

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

The returned iterator will be an L<Iterator::Flex::Array> iterator.

=item a coderef

The coderef must return the next element in the iteration.

=item a globref

=back

=cut

sub to_iterator {

    return @_
      ? construct_from_iterable( @_ )
      : construct( next => sub { return } );
}

=sub construct

  $iterator = Iterator::Flex::Factory::construct( %params );

Construct an iterator object.

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

sub construct {

    _croak( "attributes must be passed as a hashref\n" )
      unless is_hashref( $_[-1] );

    my %iattr = (
        class     => 'Iterator::Flex::Base',
        %{ $_[-1] },
    );

    my $attr;
    my %attr;
    my @roles;

    defined( my $class = delete $iattr{class} )
      or _croak( "missing or undefined 'class' attribute" );

    !is_ref( $class )
      or _croak( "'class' attribute must be a string" );

    Module::Runtime::require_module( $class )
      or _croak( "can't load class $class" );

    if ( defined( $attr = delete $iattr{name} ) ) {
        !is_ref( $attr )
          or _croak( "'name' attribute value must be a string\n" );
        $attr{name} = $attr;
    }

    # close over self 
    push @roles, [ Next => 'NoSelf' ];

    $class->_croak( "specify only one native exhaustion action" )
      if 1 < ( my ( $exhaustion_action ) =  grep { exists $iattr{$_} } @NativeExhaustionActions );

    my $has_output_exhaustion_policy =   grep { exists $iattr{$_} } @RequestedExhaustionActions;

    # default to returning undef on exhaustion
    if ( ! defined $exhaustion_action ) {
        $exhaustion_action = RETURNS_ON_EXHAUSTION;
        $iattr{+RETURNS_ON_EXHAUSTION} = undef;
    }

    if ( $exhaustion_action eq RETURNS_ON_EXHAUSTION ) {
        push @roles, [ Exhaustion => 'NativeReturn' ],
          [ Next => 'WrapReturn' ];
        $attr{+RETURNS_ON_EXHAUSTION} = delete $iattr{+RETURNS_ON_EXHAUSTION};

        $attr{+ON_EXHAUSTION_RETURN} = $attr{+RETURNS_ON_EXHAUSTION}
          unless $has_output_exhaustion_policy;
    }
    elsif ( $exhaustion_action eq THROWS_ON_EXHAUSTION ) {
        push @roles, [ Exhaustion => 'NativeThrow' ],
          [ Next => 'WrapThrow' ];
        $attr{+THROWS_ON_EXHAUSTION} = delete $iattr{+THROWS_ON_EXHAUSTION};

        $attr{+ON_EXHAUSTION_THROW} = ON_EXHAUSTION_PASSTHROUGH
          unless $has_output_exhaustion_policy;
    }
    push @roles, 'Exhausted';

    # copy over any output exhaustion policy specifications
    $attr{$_} = delete $iattr{$_} for grep { exists $iattr{$_} }  @RequestedExhaustionActions;

    for my $method ( qw[ next rewind reset prev current ] ) {

        next unless defined( my $code = delete $iattr{$method} );

        is_coderef $code
          or _croak( "'$method' attribute value must be a code reference\n" );

        # if $class can't perform the required method, add a role
        # which can
        push @roles, $class->_module_name( 'Role' => ucfirst( $method ) )
          unless $class->can( $method );

        $attr{$method} = $code;
    }
    defined( $attr{next}  )
      or _croak( "missing or undefined 'next' attribute" );

    if ( defined( $attr = delete $iattr{methods} ) ) {

        is_hashref( $attr )
          or _croak( "value for methods attribute must be a hash reference\n" );

        $attr{methods} = {};
        for my $name ( keys %{$attr} ) {

            my $code = $attr->{$name};

            !is_coderef( $code )
              and _croak(
                "value for 'methods' attribute key '$name' must be a code reference"
              );

            my $cap_name = ucfirst( $name );

            # create role for the method
            my $role = eval { Method( $cap_name, name => $name ) };

            if ( $@ ne '' ) {
                my $error = $@;
                die $error
                  unless $error->$_isa( 'Iterator::Flex::Failure::RoleExists' );

                $role = $error->payload;
            }

            push @roles, $role;
            $attr{methods}{$name} = $code;
        }
    }

    keys %iattr
      and _croak( "unknown attributes: @{[ join( ', ', keys %iattr ) ]}\n" );

    $attr{_roles} = \@roles;

    return $class->new_from_attrs( \%attr );
}

=method construct_from_iterable

  $iter = Iterator::Flex::Factory::construct_from_iterable( $iterable, %attributes );

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

    my ( $obj, %attr ) = @_;

    if ( blessed $obj) {
        return construct_from_object( $obj, %attr );
    }

    elsif ( is_arrayref( $obj ) ) {
        require Iterator::Flex::Array;
        return Iterator::Flex::Array->new( $obj, %attr );
    }

    elsif ( is_coderef( $obj ) ) {
        return construct( %attr, next => $obj );
    }

    elsif ( is_globref( $obj ) ) {
        return construct( %attr, next => sub { scalar <$obj> } );
    }

    _croak sprintf "'%s' object is not iterable", ( ref( $obj ) || 'SCALAR' );
}

=method construct_from_object

  $iter = Iterator::Flex::Factory::construct_from_object( $iterable );

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

    my $obj = shift;

    return $obj if $obj->isa( 'Iterator::Flex::Base' );

    my %param;
    my $code;

    # assume the iterator returns undef on exhausted
    $param{exhausted} = 'undef';

    if ( $code = _can_meth( $obj, 'iter' ) ) {
        $param{next} = $code->( $obj );
    }
    elsif ( $code = _can_meth( $obj, 'next' )
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
        $code = _can_meth( $obj, $method );
        $param{$method} = sub { $code->( $obj ) }
          if $code;
    }

    return construct( %param );
}

1;

# COPYRIGHT
