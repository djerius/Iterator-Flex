#! perl

use Test2::V0;

subtest '_module_name' => sub {

    package My::T::Test::Role::Utils {
        use Test2::V0;
        use parent 'Iterator::Flex::Base';

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
        use parent 'Iterator::Flex::Base';

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
        use parent 'Iterator::Flex::Base';

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


done_testing;
