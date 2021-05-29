package Iterator::Flex::Role::Utils;

# ABSTRACT: Role based utilities

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;
use Ref::Util;

=method _load_module

  $module = $class->_load_module( @path );

Search through the namespaces provided by C<< $class->_namespaces >> to load the
module whose name is given by

   $class->_module_name( $namespace, @path );

Throws C<Iterator::Flex::Failure::class> if it couldn't require
the module (for whatever reason).

=cut

sub _load_module {

    my $class = shift;
    my @path  = @_;

    for my $namespace ( $class->_namespaces ) {
        my $module = $class->_module_name( $namespace, @path );
        return $module if eval { Module::Runtime::require_module( $module ) };
    }

    $class->_throw(
        class => join ' ',
        "unable to find a module for",
        join( "::", @path ),
        , "in @{[ join( ', ', $class->_namespaces ) ]}"
    );
}

=method _load_role

  $module = $class->_load_role( @path );

Simply calls

  $class->_load_module( 'Role', @path );
=cut

sub _load_role {
    my ( $class, @path ) = @_;
    $class->_load_module( 'Role', @path );
}

=method _module_name

  $module_name = $class->_module_name( @path );

Transform C<@path> into a fully qualified module name, where
C<@path> is one or more elements in a module name (e.g., the
stuff between the C<::>).  The intent is to make it possible for
a caller to specify a module path either relative to C<$class> or absolutely.

Because C<_module_name> may be called by an internal routine which
adds things to the beginning of the path, there must be some way for a
downstream user to specify an absolute path with the part they
control, namely the last element in the path.

If the I<last> element in C<@path>

=over

=item *

does I<not> begin withC<::>

=item *

contains a C<::>

=back

It is assumed to be an absolute path, and it is returned.  For example,

  $class->_module_name( qw( foo bar bas::goo ) ) => 'bas::goo'

while

  $class->_module_name( qw( foo bar ::bas::goo ) ) => 'foo::bar::bas::goo'

If the I<first> element in C<@path>

=over

=item *

does not I<begin> withC<::>

=item *

contains a C<::>

=back

It is assumed to be an absolute path, and

  join('::', @path)

is returned.  Otherwise,

  join('::', $class, @path )

is returned.  I<However>, for internal use, if C<$class> is in the
C<Iterator::Flex> namespace, C<$class> set to C<Iterator::Flex>.

For example,

  $class->_module_name( qw( foo bar goo ) ) => "$class::foo::bar::goo"

while

  $class->_module_name( qw( ::foo bar goo ) ) => 'foo::bar::goo'

=cut


sub _module_name {
    my $class     = shift;
    my @path = @_; # copy, as we may be making changes

    my $idx;

    $idx = index( $path[-1], '::' );
    if (  $idx  > -1 ) {
        return $path[-1] if $idx > 1;
        substr( $path[-1], 0, 2, '' ) if $idx == 0;
    }

    $idx = index( $path[0], '::' );
    if (  $idx  > -1 ) {
        return join( '::', @path ) if $idx > 1;
        substr( $path[0], 0, 2, '' ) if $idx == 0;
    }

    # make sure we don't match against Iterator::Flexible or some othe class
    $class = 'Iterator::Flex' if $class =~ /^Iterator::Flex(?:::.*|$)/;

    return join( '::', $class, @path );
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

  ($name, $code ) = $class->_can_meth( $obj, @method, {name => 1, code => 1 } );

=cut


sub _can_meth {
    my $thing = shift;
    my $par = Ref::Util::is_hashref( $_[-1] ) ? pop : {};
    $thing = shift if Ref::Util::is_blessed_ref( $_[0] );

    for my $method ( @_ ) {
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

sub _throw {
    shift;
    require Iterator::Flex::Failure;
    local @Iterator::Flex::Role::Utils::CARP_NOT = scalar caller;
    my $type  = join( '::', 'Iterator::Flex::Failure', shift );
    $type->throw( { msg => shift, trace => Iterator::Flex::Failure->croak_trace } );
}


1;

# COPYRIGHT

=head1 DESCRIPTION

This is a C<Role::Tiny> role which adds a variety of utility methods to
a class.  They are structured that way so that they may be overridden
if necessary.  (Well, technically I<under-ridden> if they already exist before
this role is applied).
