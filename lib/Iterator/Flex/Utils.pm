package Iterator::Flex::Utils;

# ABSTRACT: Internal utilities

use 5.28.0; # hash slices

use strict;
use warnings;

use experimental 'signatures', 'postderef';

our $VERSION = '0.14';

use Scalar::Util qw( refaddr );
use Ref::Util qw( is_hashref );;
use Exporter 'import';

our %REGISTRY;

our %ExhaustionActions;
our %RegistryKeys;
our %IterAttrs;
our %Methods;
our %IterStates;

BEGIN {
    %ExhaustionActions = ( map { $_ => lc $_ } qw[ THROW RETURN PASSTHROUGH ] );

    %RegistryKeys
      = ( map { $_ => lc $_ }
          qw[ INPUT_EXHAUSTION EXHAUSTION ERROR STATE ITERATOR GENERAL METHODS ]
      );

    %IterAttrs = (
        map { $_ => lc $_ }
          qw[ _SELF _DEPENDS _ROLES _NAME STATE CLASS
          NEXT PREV CURRENT REWIND RESET FREEZE METHODS ]
    );

    %Methods = ( map { $_ => lc $_ } qw[ IS_EXHAUSTED SET_EXHAUSTED  ] );

    %IterStates = (
        IterState_CLEAR     => 0,
        IterState_EXHAUSTED => 1,
        IterState_ERROR     => 2,
    );
}

use constant \%ExhaustionActions;
use constant \%RegistryKeys;
use constant \%IterAttrs;
use constant \%Methods;
use constant \%IterStates;

our @InterfaceParameters;
our @SignalParameters;

BEGIN {
    @InterfaceParameters = (
        +_NAME,  +_SELF, +_DEPENDS, +_ROLES,  +STATE,   +NEXT,
        +REWIND, +RESET, +PREV,     +CURRENT, +METHODS, +FREEZE
    );
    @SignalParameters = ( +INPUT_EXHAUSTION, +EXHAUSTION, +ERROR, );
}

use constant InterfaceParameters => @InterfaceParameters;
use constant SignalParameters    => @SignalParameters;
use constant GeneralParameters   => +InterfaceParameters, +SignalParameters;

our %SignalParameters   = {}->%{ +SignalParameters };
our %InterfaceParameters = {}->%{ +InterfaceParameters };

our %EXPORT_TAGS = (
    ExhaustionActions => [ keys %ExhaustionActions, ],
    RegistryKeys      => [ keys %RegistryKeys ],
    IterAttrs         => [ keys %IterAttrs ],
    IterStates        => [ keys %IterStates ],
    Methods           => [ keys %Methods ],
    GeneralParameters => [GeneralParameters],
    Functions         => [
        qw(
          check_invalid_interface_parameters
          check_invalid_signal_parameters
          check_valid_interface_parameters
          check_valid_signal_parameters
          create_class_with_roles throw_failure
          parse_pars
        )
    ],
    default => [qw( %REGISTRY refaddr )],
);

our @EXPORT = @{ $EXPORT_TAGS{default} };

our @EXPORT_OK = ( map { @{$_} } values %EXPORT_TAGS, );


use Role::Tiny::With;
with 'Iterator::Flex::Role::Utils';

sub throw_failure ( $failure, $msg ) {
    require Iterator::Flex::Failure;
    my $type = join( '::', 'Iterator::Flex::Failure', $failure );
    $type->throw(
        { msg => $msg, trace => Iterator::Flex::Failure->croak_trace } );
}

sub create_class_with_roles ( $base, @roles ) {

    my $class = Role::Tiny->create_class_with_roles( $base,
        map { $base->_load_role( $_ ) } @roles );

    unless ( $class->can( '_construct_next' ) ) {
        throw_failure( class =>
              "Constructed class '$class' does not provide the required _construct_next method\n"
        );
    }

    return $class;
}

=sub parse_pars

  ( $mpars, $ipars, $spars ) = parse_params( \%args  );

Returns the
L<model|Iterator::Flex::Manual::Overview/Model Parameters>
L<interface|Iterator::Flex::Manual::Overview/Interface Parameters>
L<signal|Iterator::Flex::Manual::Overview/Signal Parameters>
parameters from C<%args>.

=cut

sub parse_pars ( @args ) {

    my %pars = do {

        if ( @args == 1 ) {
            throw_failure( parameter => "expected a hashref " )
              unless is_hashref( $args[0] );
            $args[0]->%*;
        }

        else {
            throw_failure(
                parameter => "expected an even number of arguments for hash" )
              if @args % 2;
            @args;
        }
    };

    my %ipars = delete %pars{ check_valid_interface_parameters( [keys %pars] ) };
    my %spars = delete %pars{ check_valid_signal_parameters( [keys %pars] ) };

    return ( \%pars, \%ipars, \%spars );
}

=sub check_invalid_interface_parameters

   @bad = check_invalid_interface_parameters( \@pars );

Returns invalid interface parameters;

=cut

sub check_invalid_interface_parameters ( $pars ) {
    return ( grep !exists $InterfaceParameters{$_}, $pars->@* );
}

=sub check_valid_interface_parameters

   @bad = check_valid_interface_parameters( \@pars );

Returns valid interface parameters;

=cut

sub check_valid_interface_parameters ( $pars ) {
    return ( grep exists $InterfaceParameters{$_}, $pars->@* );
}

=sub check_invalid_signal_parameters

   @bad = check_invalid_signal_parameters( \@pars );

Returns invalid signal parameters;

=cut

sub check_invalid_signal_parameters ( $pars ) {
    return ( grep !exists $SignalParameters{$_}, $pars->@* );
}

=sub check_valid_signal_parameters

   @bad = check_valid_signal_parameters( \@pars );

Returns valid signal parameters;

=cut

sub check_valid_signal_parameters ( $pars ) {
    return ( grep exists $SignalParameters{$_}, $pars->@* );
}

1;

# COPYRIGHT
