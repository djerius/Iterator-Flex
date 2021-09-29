package Iterator::Flex::Factory;

# ABSTRACT: Create on-the-fly Iterator::Flex classes/objects

use 5.25.0;
use strict;
use warnings;

use experimental qw( signatures declared_refs );

our $VERSION = '0.12';

use Ref::Util        ();
use Role::Tiny       ();
use Role::Tiny::With ();
use Module::Runtime;

use Iterator::Flex::Base;
use Iterator::Flex::Utils qw[
  :ExhaustionActions
  :default
  :RegistryKeys
  :IterAttrs
];

Role::Tiny::With::with 'Iterator::Flex::Role::Utils';

=class_method to_iterator

  $iter = Iterator::Flex::Factory->to_iterator( $iterable, \%gpar );

Construct an iterator from an iterable thing. The C<%gpar> parameter
may contain
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


See L</construct_from_object>

=item an arrayref

The returned iterator will be an L<Iterator::Flex::Array> iterator.

=item a coderef

The coderef must return the next element in the iteration.

=item a globref

=back

=cut

sub to_iterator ( $CLASS, $iterable = undef, $pars = {} ) {
    return
      defined $iterable
      ? $CLASS->construct_from_iterable( $iterable, $pars )
      : $CLASS->construct( {
            (+NEXT) => sub { }
        } );
}



############################################################################

=class_method construct

  $iterator = Iterator::Flex::Factory->construct( %params );

Construct an iterator object.

The following parameters are accepted:

=over

=item name I<optional>

An optional name to be output during error messages

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

A subroutine which returns the next value.

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
will be the first element from the iterator.  It should not alter the values
returned by L</prev> or L</current>.

=back

The following parameters define how iterator exhaustion is handled. It is separated into
two classes: I<native> exhaustion and I<output> exhaustion.  I<Native> exhaustion describes
how the I<next> method expresses exhaustion, while I<output> exhaustion describes how the
generated iterator should express exhaustion.

=over

=item native_exhaustion => I<spec>

I<spec> can be one of the following:

=over

=item C<throw>

=item [ C<throw> => I<exception string or object> ]

The iterator will signal its exhaustion by throwing an exception.

=item C<return>

=item [ C<return> => I<sentinel value> ]

The iterator will signal its exhaustion by returning a sentinel value.
If not specified, it is C<undef>.

=back

=item exhaustion => i<spec>

I<spec> can be one of the following:

=over

=item C<throw>

=item [ C<throw> => I<exception string or object> ]

=item C<return>

=item [ C<return> => I<sentinel value> ]

=item C<passthrough>

=back

=back

=cut

sub construct ( $CLASS, $in_ipar = {}, $in_gpar = {} ) {

    $CLASS->_throw(
        parameter => "iterator parameters parameter must be a hashref" )
      unless Ref::Util::is_hashref( $in_ipar );

    $CLASS->_throw(
        parameter => "general parameters parameter must be a hashref" )
      unless Ref::Util::is_hashref( $in_gpar );

    my %ipar = $in_ipar->%*;
    my %ipar_k;
    @ipar_k{ keys %ipar } = ();
    my %gpar = $in_gpar->%*;
    my %gpar_k;
    @gpar_k{ keys %gpar } = ();

    my $par;
    my @roles;

    my $class = $ipar{class} // 'Iterator::Flex::Base';
    delete $ipar_k{class};

    $CLASS->_throw( parameter => "'class' parameter must be a string" )
      if Ref::Util::is_ref( $class );

    $CLASS->_throw( parameter => "can't load class $class" )
      if $class ne 'Iterator::Flex::Base'
      && !Module::Runtime::require_module( $class );

    delete $ipar_k{+_NAME};
    $CLASS->_throw( parameter => "'@{[ _NAME ]}' parameter value must be a string\n" )
      if defined( $par = $ipar{+_NAME} ) && Ref::Util::is_ref( $par );

    push @roles, 'Exhausted::Registry';

    delete $gpar_k{ +INPUT_EXHAUSTION };
    my $input_exhaustion = $gpar{ +INPUT_EXHAUSTION }
      // [ RETURN, undef ];

    my @input_exhaustion
      = Ref::Util::is_arrayref( $input_exhaustion )
      ? ( $input_exhaustion->@* )
      : ( $input_exhaustion );

    delete $gpar_k{ +EXHAUSTION };
    my $has_output_exhaustion_policy = defined $gpar{ +EXHAUSTION };

    if ( $input_exhaustion[0] eq RETURN ) {
        push @roles, 'Exhaustion::ImportedReturn','Wrap::Return';
        push $input_exhaustion->@*, undef if @input_exhaustion == 1;
        $gpar{ +INPUT_EXHAUSTION } = \@input_exhaustion;
        $gpar{ +EXHAUSTION }       = $gpar{ +INPUT_EXHAUSTION }
          unless $has_output_exhaustion_policy;
    }

    elsif ( $input_exhaustion[0] eq THROW ) {
        push @roles,  'Exhaustion::ImportedThrow', 'Wrap::Throw';
        $gpar{ +INPUT_EXHAUSTION } = \@input_exhaustion;
        $gpar{ +EXHAUSTION }       = [ (+THROW) => PASSTHROUGH ]
          unless $has_output_exhaustion_policy;
    }

    $CLASS->_throw( parameter => "missing or undefined 'next' parameter" )
      if !defined( $ipar{+NEXT} );

    for my $method ( +NEXT, +REWIND, +RESET, +PREV, +CURRENT  ) {

        delete $ipar_k{$method};
        next unless defined( my $code = $ipar{$method} );

        $CLASS->_throw( parameter =>
              "'$method' parameter value must be a code reference\n" )
          unless Ref::Util::is_coderef( $code );

        # if $class can't perform the required method, add a role
        # which can.
        if ( $method eq +NEXT ) {
            # next is always a closure, but the caller may want to
            # keep track of $self
            push @roles, defined $ipar{+_SELF} ? 'Next::ClosedSelf' : 'Next::Closure';
            delete $ipar_k{+_SELF};
        }
        else {
            my $impl = $class->can( $method ) ?  'Method' : 'Closure';
            push @roles, ucfirst( $method ) . '::' . $impl;
        }
    }

    # these are dealt with in the iterator constructor.
    delete $ipar_k{ +METHODS };

    if ( !!%ipar_k || !!%gpar_k ) {

        $CLASS->_throw( parameter =>
              "unknown iterator parameters: @{[ join( ', ', keys %ipar_k ) ]}" )
          if %ipar_k;
        $CLASS->_throw( parameter =>
              "unknown iterator parameters: @{[ join( ', ', keys %gpar_k ) ]}" )
          if %gpar_k;
    }

    $ipar{_roles} = \@roles;

    return $class->new_from_attrs( \%ipar, \%gpar );
}

=class_method construct_from_iterable

  $iter = Iterator::Flex::Factory->construct_from_iterable( $iterable, %parameters );

Construct an iterator from an
L<Iterator::Flex::Manual::Glossary/iterable thing>.  The returned
iterator will return C<undef> upon exhaustion.

If C<$iterable> is:

=over

=item *

an object, the arguments are passed to L</construct_from_object>.

=item *

an array, the arguments are passed to L<Iterator::Flex::Array/new>.

=item *

a coderef, the arguments are passed to L</construct>.

=item *

a globref, the arguments are passed to L</construct>.

=back

=cut


sub construct_from_iterable ( $CLASS, $obj, $pars = {} ) {

    my ( $ipars, $gpars ) = $CLASS->_parse_pars( $pars );


    if ( Ref::Util::is_blessed_ref( $obj ) ) {
        return $CLASS->construct_from_object( $obj, $ipars, $gpars );
    }

    elsif ( Ref::Util::is_arrayref( $obj ) ) {
        return $CLASS->construct_from_array( $obj, $gpars );
    }

    elsif ( Ref::Util::is_coderef( $obj ) ) {
        return $CLASS->construct( { $ipars->%*, next => $obj }, $gpars );
    }

    elsif ( Ref::Util::is_globref( $obj ) ) {
        return $CLASS->construct( {
                $ipars->%*, next => sub { scalar <$obj> }
            },
            $gpars
        );
    }

    $CLASS->_throw(
        parameter => sprintf "'%s' object is not iterable",
        ( ref( $obj ) || 'SCALAR' ) );
}

=class_method construct_from_array

  $iter = Iterator::Flex::Factory->construct_from_array( $array_ref, %parameters );

=cut

sub construct_from_array ( $, $obj, $gpars ) {
    require Iterator::Flex::Array;
    return Iterator::Flex::Array->new( $obj, $gpars );
}

=class_method construct_from_object

  $iter = Iterator::Flex::Factory->construct_from_object( $object, %parameters );

Construct an iterator from an L<Iterator::Flex::Manual::Glossary/iterable object>.
Normal use is to call L</to_iterator>, L</construct_from_iterable> or
simply use L<Iterator::Flex/iter>.

If the object has the following methods, they are used
by the constructed iterator:

=over

=item C<__prev__> or C<prev>

=item C<__current__> or C<current>

=back

=cut


sub construct_from_object ( $CLASS, $obj, $ipar, $gpar ) {

    $CLASS->_throw( parameter => q['$object' parameter is not a real object] )
      unless Ref::Util::is_blessed_ref($obj);

    return construct_from_iterator_flex( $CLASS, $obj, $ipar, $gpar )
      if $obj->isa( 'Iterator::Flex::Base' );

    my %ipar = $ipar->%*;
    my %gpar = $gpar->%*;

    $gpar{ +INPUT_EXHAUSTION } //= [ (+RETURN) => undef ];

    if ( !exists $ipar{next} ) {
        my $code;
        if ( $code = $CLASS->_can_meth( $obj, 'iter' ) ) {
            $ipar{next} = $code->( $obj );
        }
        elsif ( $code = $CLASS->_can_meth( $obj, 'next' )
            || overload::Method( $obj, '<>' ) )
        {
            $ipar{next} = sub { $code->( $obj ) };
        }

        elsif ( $code = overload::Method( $obj, '&{}' ) ) {
            $ipar{next} = $code->( $obj );
        }

        elsif ( $code = overload::Method( $obj, '@{}' ) ) {
            return $CLASS->construct_from_array( $code->( $obj ), $ipar,
                \%gpar );
        }

    }

    for my $method ( grep { !exists $ipar{$_} } 'prev', 'current' ) {
        my $code = $CLASS->_can_meth( $obj, $method );
        $ipar{$method} = sub { $code->( $obj ) }
          if $code;
    }

    return $CLASS->construct( \%ipar, \%gpar );
}

sub construct_from_iterator_flex ( $CLASS, $obj, $, $gpar ) {

    my @exhaustion = do {
        my $exhaustion = $gpar->{ +EXHAUSTION };
        return $obj unless defined $exhaustion;

        Ref::Util::is_arrayref( $exhaustion )
          ? ( $exhaustion->@* )
          : ( $exhaustion );
    };

    my \%registry
      = exists $REGISTRY{ refaddr $obj }
      ? $REGISTRY{ refaddr $obj }{ +GENERAL }
      : $CLASS->_throw( internal => "non-registered Iterator::Flex iterator" );


    # multiple different output exhaustion roles may have been
    # applied, so the object may claim to support both roles,
    # Exhaustion::Throw and Exhaustion::Return, although only the
    # latest one applied will work.  So, use what's in the registry to
    # figure out what it actually does.

    my $existing_exhaustion = $registry{ +EXHAUSTION }[0]
      // $CLASS->_throw( internal =>
          "registered Iterator::Flex iterator doesn't have a registered exhaustion"
      );

    if ( $exhaustion[0] eq RETURN ) {

        if ( $existing_exhaustion eq +THROW ) {
            Role::Tiny->apply_roles_to_object( $obj,
                $obj->_load_role( 'Exhaustion::Return' ) );
        }
    }

    elsif ( $exhaustion[0] eq THROW ) {

        if ( $existing_exhaustion eq +THROW ) {
            Role::Tiny->apply_roles_to_object( $obj,
                $obj->_load_role( 'Exhaustion::Return' ) );
        }

        if ( $existing_exhaustion eq +RETURN ) {
            Role::Tiny->apply_roles_to_object( $obj,
                $obj->_load_role( 'Exhaustion::Throw' ) );
        }
    }

    else {
        $CLASS->_throw( internal =>
            "unexpected exhaustion action: $exhaustion[0]" );
    }

    $registry{ +EXHAUSTION }->@* = @exhaustion;
    return $obj;
}

sub construct_from_attr ( $CLASS, $in_ipar = {}, $in_gpar = {} ) {
    my %gpar = $in_gpar->%*;

    # this indicates that there should be no wrapping of 'next'
    $gpar{+INPUT_EXHAUSTION} = +PASSTHROUGH;
    $CLASS->construct( $in_ipar, \%gpar );
}

=class_method _parse_pars

  ( \%iter_pars, \%general_pars ) = $class->_parse_pars( \%pars );

=cut

sub _parse_pars ( $, $pars ) {

    my %ipars = $pars->%*;
    # move  general parsibutes into their own hash
    my %gpars = delete %ipars{ +EXHAUSTION, +INPUT_EXHAUSTION };

    delete %gpars{ grep { !defined $gpars{$_} } keys %gpars };

    return \%ipars, \%gpars;
}

1;

# COPYRIGHT
