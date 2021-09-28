package Iterator::Flex::Role::Wrap::Throw;

# ABSTRACT: Role to add throw on exhaustion to an iterator which sets is_exhausted.

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Utils qw( :RegistryKeys INPUT_EXHAUSTION );
use Scalar::Util;
use Ref::Util qw( is_regexpref is_arrayref is_coderef );
use Role::Tiny;

use namespace::clean;

around _construct_next => sub {

    my $orig  = shift;
    my $gpar = $_[-1];
    my $next  = $orig->( @_ );

    my $exception = (
        $gpar->{ +INPUT_EXHAUSTION } // do {
            require Iterator::Flex::Failure;
            Iterator::Flex::Failure::parameter->throw(
                "internal error: input exhaustion policy was not registered" );
          }
    )->[1];

    my $wsub;

    if ( is_arrayref( $exception ) ) {

        $wsub = sub {
            my $val = eval { $next->( $_[0] ) };
            if ( $@ ne '' ) {
                my $e = $@;
                return $_[0]->signal_exhaustion( $e )
                  if is_blessed_ref( $e ) && grep { $e->isa( $_ ) } @$exception;
                die $e;
            }
            return $val;
        };
    }

    elsif ( is_regexpref( $exception ) ) {

        $wsub = sub {
            my $val = eval { $next->( $_[0] ) };
            if ( $@ ne '' ) {
                my $e = $@;
                return $_[0]->signal_exhaustion( $e ) if $e =~ $exception;
                die $e;
            }
            return $val;
        };
    }

    elsif ( is_coderef( $exception ) ) {

        $wsub = sub {
            my $val = eval { $next->( $_[0] ) };
            if ( $@ ne '' ) {
                my $e = $@;
                return $_[0]->signal_exhaustion( $e ) if $exception->( $e );
                die $e;
            }
            return $val;
        };
    }

    else {

        $wsub = sub {
            my $val = eval { $next->( $_[0] ) };
            return $@ ne '' ? $_[0]->signal_exhaustion( $@ ) : $val;
        };
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
