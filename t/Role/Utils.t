#! perl

use Test2::V0;

package My::T::Role::Utils { 
    use Package::Stash;

    sub ::Pkg {
        my $package = scalar caller;
        my $stash = Package::Stash->new($package);
        $stash->add_symbol('$TEMPLATE', 'Package0000' )
          unless $stash->has_symbol('$TEMPLATE');

        my $name = *{$stash->namespace->{TEMPLATE}}{SCALAR};
        ++ ${$name};
        Package::Stash->new( $package . '::' . ${$name} );
    }
}

subtest '_module_name' => sub {

    package My::T::Role::Utils::_module_name {
        use Test2::V0;
        use Role::Tiny::With;
        with 'Iterator::Flex::Role::Utils';


        subtest 'user package' => sub {
            is( __PACKAGE__->_module_name( qw( foo bar bas ) ),
                join( '::', __PACKAGE__, qw( foo bar bas ) ), 'relative' );

            is( __PACKAGE__->_module_name( qw( foo bar bas::goo ) ),
                'bas::goo', 'absolute at [-1]' );

            is( __PACKAGE__->_module_name( qw( foo::bar bas goo ) ),
                'foo::bar::bas::goo', 'absolute at [0]' );

        };

    }

    package Iterator::Flex::Test::Foo {
        use Test2::V0;
        use Role::Tiny::With;
        with 'Iterator::Flex::Role::Utils';

        subtest 'Iterator::Flex::...' => sub {
            is( __PACKAGE__->_module_name( qw( foo bar bas ) ),
                join( '::', 'Iterator::Flex', qw( foo bar bas ) ), 'relative' );

            is( __PACKAGE__->_module_name( qw( foo bar bas::goo ) ),
                'bas::goo', 'absolute at [-1]' );

            is( __PACKAGE__->_module_name( qw( foo::bar bas goo ) ),
                'foo::bar::bas::goo', 'absolute at [0]' );
        };

    }

    package Iterator::Flex {
        use Test2::V0;
        use parent 'Iterator::Flex::Base';

        subtest 'Iterator::Flex' => sub {
            is( __PACKAGE__->_module_name( qw( foo bar bas ) ),
                join( '::', __PACKAGE__, qw( foo bar bas ) ), 'relative' );

            is( __PACKAGE__->_module_name( qw( foo bar bas::goo ) ),
                'bas::goo', 'absolute at [-1]' );

            is( __PACKAGE__->_module_name( qw( foo::bar bas goo ) ),
                'foo::bar::bas::goo', 'absolute at [0]' );
        };
    }

    package Iterator::Flexibility {
        use Test2::V0;
        use Role::Tiny::With;
        with 'Iterator::Flex::Role::Utils';

        subtest 'Iterator::Flexibility' => sub {
            is( __PACKAGE__->_module_name( qw( foo bar bas ) ),
                join( '::', __PACKAGE__, qw( foo bar bas ) ), 'relative' );

            is( __PACKAGE__->_module_name( qw( foo bar bas::goo ) ),
                'bas::goo', 'absolute at [-1]' );

            is( __PACKAGE__->_module_name( qw( foo::bar bas goo ) ),
                'foo::bar::bas::goo', 'absolute at [0]' );
        };
    }


};

subtest '_can_meth' => sub {

    package My::T::Role::Utils::_can_meth;
    use Test2::V0;
    use Role::Tiny::With;
    with 'Iterator::Flex::Role::Utils';

    my $_can_meth = \&_can_meth;

    subtest 'class' => sub {
        my $pkg = ::Pkg;

        subtest 'reverse order' => sub {
            # add in reverse order of lookup
            for my $method ( 'method1', '__method1__' ) {
                $pkg->add_symbol( '&' . $method, sub { } );

                is( $pkg->name->$_can_meth( $method ),
                    $pkg->get_symbol( '&' . $method ), $method );
            }
        };

        subtest 'normal order' => sub {
            # add in order of lookup. should always get __method__
            for my $method ( '__method2__', 'method2' ) {
                $pkg->add_symbol( '&' . $method, sub { } );

                is( $pkg->name->$_can_meth( $method ),
                    $pkg->get_symbol( '&__method2__' ), $method );
            }
        };
    };

    subtest 'object' => sub {
        my $pkg = ::Pkg;
        my $obj = bless {}, $pkg->name;

        subtest 'reverse order' => sub {
            # add in reverse order of lookup
            for my $method ( 'method1', '__method1__' ) {
                $pkg->add_symbol( '&' . $method, sub { } );

                is( $pkg->name->$_can_meth( $obj, $method ),
                    $pkg->get_symbol( '&' . $method ), $method );
            }
        };

        subtest 'normal order' => sub {
            # add in order of lookup. should always get __method__
            for my $method ( '__method2__', 'method2' ) {
                $pkg->add_symbol( '&' . $method, sub { } );

                is( $pkg->name->$_can_meth( $obj, $method ),
                    $pkg->get_symbol( '&__method2__' ), $method );
            }
        };
    };

    subtest 'return value' => sub {

        my $pkg = ::Pkg;
        $pkg->add_symbol( '&__method__', sub { } );

        is ( $pkg->name->$_can_meth( 'method', { name => 1 } ),
             '__method__', 'name' );

        is ( $pkg->name->$_can_meth( 'method', { code => 1 } ),
             $pkg->get_symbol( '&__method__' ), 'code' );

        is ( [ $pkg->name->$_can_meth( 'method', { code => 1, name => 1 } ) ],
             [ '__method__', $pkg->get_symbol( '&__method__' ) ], 'name + code' );
    }

};

subtest '_throw' => sub {

    package My::T::Role::Utils::_throw;
    use Test2::V0;
    use Role::Tiny ();

    subtest 'class' => sub {
        my $pkg = ::Pkg;
        Role::Tiny->apply_roles_to_package( $pkg->name, 'Iterator::Flex::Role::Utils' );

        my $name = $pkg->name;

        like (
            dies { eval "package $name; __PACKAGE__->_throw( internal => 'foo' )"; die $@ if $@ ne '' },
              qr|Failure caught at t/Role/Utils.t line \d+\.$|m,
        );

    };


};

done_testing;
