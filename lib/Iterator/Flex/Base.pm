package Iterator::Flex::Base;

# ABSTRACT: Iterator object

use strict;
use warnings;

our $VERSION = '0.10';

use Scalar::Util;
use Ref::Util;
use Role::Tiny       ();
use Role::Tiny::With ();

Role::Tiny::With::with 'Iterator::Flex::Role';

use Iterator::Flex::Failure;

our %REGISTRY;

use overload ( '<>' => 'next', fallback => 1 );

sub _ITERATOR_BASE {
    require Iterator::Flex;
    goto \&Iterator::Flex::_ITERATOR_BASE;
}

sub _croak {
    my $class = ref $_[0] || $_[0];
    shift;
    require Carp;
    Carp::croak( "$class: ", @_ );
}

sub new {

    my $class = shift;

    return $class->new_from_attrs( $class->construct( @_ ) );
}

sub new_from_state {

    my $class = shift;

    return $class->new_from_attrs( $class->construct_from_state( @_ ) );

}

sub new_from_attrs {

    my ( $class, $attrs ) = ( shift, shift );

    # copy attrs as we may change it
    my %attrs = ( _roles => [], %$attrs );
    $class->_validate_attrs( \%$attrs );

    # add roles if necessary
    if ( @{ $attrs{_roles} } ) {

	$class->_croak( "_roles must be an arrayref" )
	    unless Ref::Util::is_arrayref( $attrs{_roles} );

	$class = Role::Tiny->create_class_with_roles( $class,
						      map { "Iterator::Flex::Role::$_" }
						      @{ $attrs{_roles} } );
    }

    my $self = bless $class->_construct_next( $attrs ), $class;

    $REGISTRY{ Scalar::Util::refaddr $self } = $attrs;

    $self->set_exhausted(0);

    return $self;
}

sub _validate_attrs {

    my $class = shift;
    my $attrs = shift;

    my %iattr = %$attrs;

    my $attr;

    if ( defined( $attr = delete $iattr{depends} ) ) {

        $attr = [ $attr ] unless Ref::Util::is_arrayref( $attr );
        $attrs->{depends} = $attr;

        $class->_croak( "dependency #$_ is not an iterator object\n" )
          for grep {
            !( Scalar::Util::blessed( $attr->[$_] )
                && $attr->[$_]->isa( $class->_ITERATOR_BASE ) )
          } 0 .. $#{$attr};
    }

    return;
}

sub DESTROY {

    if ( defined $_[0] ) {
        my $attributes = delete $REGISTRY{ Scalar::Util::refaddr $_[0] };
        delete $attributes->{_overload_next};
    }
}

sub _can_meth {

    # my $class = shift;
    shift;
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
    my $attributes = $REGISTRY{ Scalar::Util::refaddr $_[0] };
    $attributes->{is_exhausted} = @_ > 1 ? $_[1] : 1;
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
    my $attributes = $REGISTRY{ Scalar::Util::refaddr $_[0] };
    !! $attributes->{is_exhausted};
}

=method __iter__

   $sub = $iter->__iter__;

Returns the subroutine which returns the next value from the iterator.

=cut

sub __iter__ {
    my $attributes = $REGISTRY{ Scalar::Util::refaddr $_[0] };
    $attributes->{next};
}

=method may

  $bool = $iter->may( $method );

Similar to L<can|UNIVERSAL/can>, except it checks to ensure that the
method can be called on the iterators which C<$iter> depends on.  For
example, it's possible that C<$iter> implements a C<rewind> method,
but that it's dependencies do not.  In that case C<can|UNIVESAL/can>
will return true, but C<may> will return false.

=cut

sub may {
    return undef;
}

sub _may_meth {

    my $obj  = shift;
    my $meth = shift;

    my $attributes = shift
      // $Iterator::Flex::Base::REGISTRY{ Scalar::Util::refaddr $obj };

    my $pred = "_may_$meth";

    $attributes->{$pred} //=
      defined $attributes->{depends}
      ? !List::Util::first { !$_->may( $meth ) } @{ $attributes->{depends} }
      : 1;

    return $attributes->{$pred};
}

sub _wrap_may {

    # my $class  = shift;
    shift;
    my $meth = shift;

    return sub {
        my $orig = shift;
        my ( $obj, $what ) = @_;

        return $obj->_may_meth( $meth )
          if $what eq $meth;

        &$orig;
    };

}

# return the role name for a given method
sub _method_to_role {
    # ( $class, $method )
    return ucfirst $_[1];
}

sub _add_roles {
    my $class = shift;

    Role::Tiny->apply_roles_to_package( $class,
        map { "Iterator::Flex::Role::$_" } @_ );
}

=method to_iterator

  $iter = $class->to_iterator( $iterable );

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

    my $class = shift;

    return $class->_ITERATOR_BASE->construct( next => sub { return } )
      unless @_;

    $class->_ITERATOR_BASE->construct_from_iterable( @_ );
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

    $class->_croak( "construct_from_iterable is a class method\n" )
      if Scalar::Util::blessed $class;

    my ( $obj ) = @_;

    if ( Scalar::Util::blessed $obj) {

        return $class->construct_from_object( $obj );
    }

    elsif ( Ref::Util::is_arrayref( $obj ) ) {

        require Iterator::Flex::Array;
        return Iterator::Flex::Array->new( $obj );
    }

    elsif ( Ref::Util::is_coderef( $obj ) ) {

        return $class->construct( next => $obj );
    }

    elsif ( Ref::Util::is_globref( $obj ) ) {
        return $class->construct( next => sub { scalar <$obj> } );
    }

    $class->_croak( sprintf "'%s' object is not iterable",
      ( ref( $obj ) || 'SCALAR' ) );

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

    $class->_croak( "construct_from_object is a class method\n" )
      if Scalar::Util::blessed $class;


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
