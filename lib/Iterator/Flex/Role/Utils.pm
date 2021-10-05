package Iterator::Flex::Role::Utils;

# ABSTRACT: Role based utilities

use strict;
use warnings;

our $VERSION = '0.13';

use Ref::Util;

use Role::Tiny;
use experimental 'signatures';

=method _load_module

  $module = $class->_load_module( @path );

Search through the namespaces provided by C<< $class->_namespaces >> to load the
module whose name is given by

   $class->_module_name( $namespace, @path );

Throws C<Iterator::Flex::Failure::class> if it couldn't require
the module (for whatever reason).

=cut

sub _load_module ( $class, $path, $namespaces ) {

    if ( substr( $path, 0, 1 ) eq '+' ) {
        my $module = substr( $path, 1 );
        return $module if eval { Module::Runtime::require_module( $module ) };
        $class->_throw( class => "unable to load $module" );
    }
    else {
        $namespaces //= [ $class->_namespaces ];

        for my $namespace ( @{ $namespaces} ) {
            my $module = $namespace . '::' . $path;
            return $module if eval { Module::Runtime::require_module( $module ) };
        }
    }

    $class->_throw(
        class => join ' ',
        "unable to find a module for '$path' in @{[ join( ', ', $class->_namespaces ) ]}"
    );
}

=method _load_role

  $module = $class->_load_role( @path );

Simply calls

  $class->_load_module( 'Role', @path );

=cut

sub _load_role ( $class, $path ) {
    $class->_load_module( $path, [ $class->_role_namespaces ] );
}


=method _can_meth

  $code = $class->_can_meth( @methods, ?\%pars  );
  $code = $class->_can_meth( $obj, @method, ?\%pars );

Scans an object to see if it provides one of the specified
methods. For each C<$method> in C<@methods>, it probes for
C<__$method__>, then C<$method>.

By default, it returns a reference to the first method it finds, otherwise C<undef> if none was found.

The return value can be altered using C<%pars>.

=over

=item name

return the name of the method.

=item code

return the coderef of the method. (Default)

=back

If both C<code> and C<name> are specified, both are returned as a list, C<name> first:

  ($name, $code ) = $class->_can_meth( $obj, @methods, {name => 1, code => 1 } );

=cut


sub _can_meth ( $self, @methods ) {

    my $thing = Ref::Util::is_blessed_ref( $methods[0] ) ? shift @methods : $self;

    my $par = Ref::Util::is_hashref( $methods[-1] ) ? pop @methods : {};

    for my $method ( @methods) {
        $self->_throw( parameter => "'method' parameters must be a string" )
          if Ref::Util::is_ref( $method );

        my $sub;
        foreach ( "__${method}__", $method ) {
            if ( defined( $sub = $thing->can( $_ ) ) ) {
                my @ret = ( ( !!$par->{name} ? $_ : () ),
                            ( !!$par->{code} ? $sub : () ) );
                push @ret, $sub unless @ret;
                return @ret > 1 ? @ret : $ret[0];
            }
        }
    }

    return undef;
}

=for stopwords
fallbacks

=cut

=method _resolve_meth

  $code = $obj->_resolve_meth( $target, $method, @fallbacks );

Return a coderef to the specified method or one of the fallbacks.

If C<$method> is a coderef, it is returned.

If C<$method> is defined and is not a coderef, it is checked for directly via C<$target->can>.
If it does not exist, a C<Iterator::Flex::Failure::parameter> error is thrown.

If C<$method> is not defined, then C<< $obj->_can_meth( $target, @fallbacks ) >> is returned.

=cut

sub _resolve_meth ( $obj, $target, $method, @fallbacks ) {

    my $code = do {

        if ( defined $method ) {
            Ref::Util::is_coderef( $method )
              ? $method
              : $target->can( $method )
              // $obj->_throw( parameter =>
                  qq{method '$method' is not provided by the object} );
        }

        else {
            $obj->_can_meth( $target, @fallbacks );
        }
    };

    return $code;
}

=method _throw

  $obj->_throw( $type => $message );

Throw an exception object of class C<Iterator::Flex::Failure::$type> with the given message.

=cut


sub _throw ( $self, $failure, $msg ) {
    require Iterator::Flex::Failure;
    local @Iterator::Flex::Role::Utils::CARP_NOT = scalar caller;
    my $type  = join( '::', 'Iterator::Flex::Failure', $failure );
    $type->throw( { msg => $msg, trace => Iterator::Flex::Failure->croak_trace } );
}


1;

# COPYRIGHT

=head1 DESCRIPTION

This is a C<Role::Tiny> role which adds a variety of utility methods to
a class.  They are structured that way so that they may be overridden
if necessary.  (Well, technically I<under-ridden> if they already exist before
this role is applied).
