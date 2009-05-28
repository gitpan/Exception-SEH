use strict;
use Test::More tests => 14;
use Test::Exception;

use Exception::SEH;

my $foo;
{
	sub _t1{
		my $todie = shift;

		try{
			$foo = 11;
			die $todie if $todie;
			$foo = 12;
		} catch (X $e) {
			$foo = 13;
		}
	}

	$foo = 10;
	lives_ok { _t1(0) };
	is($foo, 12);

	$foo = 10;
	lives_ok { _t1(bless {}, 'X') };
	is($foo, 13);

	$foo = 10;
	dies_ok { _t1(1) };
	is($foo, 11);
}

{
	sub _t2{
		my $todie = shift;

		try{
			$foo = 14;
			die 'dead' if $todie;
			$foo = 15;
		} catch {
			die $@;
		}
	}

	$foo = 10;
	lives_ok { _t2(0) };
	is($foo, 15);

	$foo = 10;
	throws_ok { _t2(1) } qr/dead/;
	is($foo, 14);
}

{
	sub _t3{
		my $todie = shift;

		try{
			$foo = 16;
			die 'dead' if $todie;
		} catch ($e) {
			die $e;
		}
		$foo = 17;
	}

	$foo = 10;
	lives_ok { _t3(0) };
	is($foo, 17);

	$foo = 10;
	throws_ok { _t3(1) } qr/dead/;
	is($foo, 16);
}
