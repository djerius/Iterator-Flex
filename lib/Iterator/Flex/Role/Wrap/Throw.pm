package Iterator::Flex::Role::Wrap::Throw;

# ABSTRACT: Role to add throw on exhaustion to an iterator which adapts another iterator

use strict;
use warnings;

our $VERSION = '0.16';

use Iterator::Flex::Utils qw( :RegistryKeys INPUT_EXHAUSTION PASSTHROUGH );
use Ref::Util             qw( is_ref is_blessed_ref is_regexpref is_arrayref is_coderef );
use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

around _construct_next => sub ( $orig, $class, $ipar, $gpar ) {

    my $next = $class->$orig( $ipar, $gpar );

    my $exception = (
        $gpar->{ +INPUT_EXHAUSTION } // do {
            require Iterator::Flex::Failure;
            Iterator::Flex::Failure::parameter->throw(
                "internal error: input exhaustion policy was not registered" );
        }
    )->[1];

    my $wsub;

    if ( !defined $exception ) {

        $wsub = sub {
            my $self = $_[0] // $wsub;
            my $val  = eval { $next->( $self ) };
            return $@ ne '' ? $self->signal_exhaustion( $@ ) : $val;
        };
    }

    elsif ( !is_ref( $exception ) && $exception eq +PASSTHROUGH ) {

        $wsub = sub {
            my $self = $_[0] // $wsub;
            my $val  = eval { $next->( $self ) };
            return $@ ne '' ? $self->signal_exhaustion( $@ ) : $val;
        };
    }

    elsif ( !is_ref( $exception ) || is_arrayref( $exception ) ) {
        $exception = [$exception]
          unless is_arrayref( $exception );

        $wsub = sub {
            my $self = $_[0] // $wsub;
            my $val  = eval { $next->( $self ) };
            if ( $@ ne '' ) {
                my $e = $@;
                return $self->signal_exhaustion( $e )
                  if is_blessed_ref( $e ) && grep { $e->isa( $_ ) } @$exception;
                die $e;
            }
            return $val;
        };
    }

    elsif ( is_regexpref( $exception ) ) {

        $wsub = sub {
            my $self = $_[0] // $wsub;
            my $val  = eval { $next->( $self ) };
            if ( $@ ne '' ) {
                my $e = $@;
                return $self->signal_exhaustion( $e ) if $e =~ $exception;
                die $e;
            }
            return $val;
        };
    }

    elsif ( is_coderef( $exception ) ) {

        $wsub = sub {
            my $self = $_[0] // $wsub;
            my $val  = eval { $next->( $self ) };
            if ( $@ ne '' ) {
                my $e = $@;
                return $self->signal_exhaustion( $e ) if $exception->( $e );
                die $e;
            }
            return $val;
        };
    }

    else {
        require Iterator::Flex::Failure;
        require Scalar::Util;
        Iterator::Flex::Failure::parameter->throw(
            "internal error: unknown type for input exhaustion policy: ${ \Scalar::Util::reftype( $exception ) }"
        );

    }


    # create a second reference to $wsub, before we weaken it,
    # otherwise it will lose its contents, as it would be the only
    # reference.

    my $sub = $wsub;
    Scalar::Util::weaken( $wsub );
    return $sub;
};

requires 'signal_exhaustion';

1;

# COPYRIGHT
