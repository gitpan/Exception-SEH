use strict;
use Test::More tests => 8;
use Test::Exception;

use Exception::SEH;

my $foo;
sub _t1{
	shift;
	try {
		$foo = 11;
		_t2($_[1]);
	} catch (X $e){
		$foo = 13;
	}
}

sub _t2{
	my $todie = shift;
	try{
		die $todie if $todie;
		$foo = 12;
	} catch (Z $e){
		$foo = 14;
	}
}

$foo = 10;
lives_ok { _t1(1, 1, 0) };
is($foo, 12);

$foo = 10;
throws_ok { _t1(1, 1, 'dead') } qr/dead/;
is($foo, 11);

$foo = 10;
lives_ok { _t1(1, 1, (bless {}, "Z")) };
is($foo, 14);

$foo = 10;
lives_ok { _t1(1, 1, (bless {}, "X")) };
is($foo, 13);