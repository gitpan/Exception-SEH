use strict;
use Test::More tests => 8;
use Test::Exception;

use Exception::SEH;

my $foo;
sub _t1{
	my $todie = shift;

	try{
		$foo = 11;
		die 'dead' if $todie;
		$foo = 12;
	}
}

$foo = 10;
lives_ok { _t1(0) };
is($foo, 12);

$foo = 10;
throws_ok { _t1(1) } qr/dead/;
is($foo, 11);

sub _t2{
	my $todie = shift;

	try{
		$foo = 13;
		die 'dead' if $todie;
	}
	$foo = 14;
}

$foo = 10;
lives_ok { _t2(0) };
is($foo, 14);

$foo = 10;
throws_ok { _t2(1) } qr/dead/;
is($foo, 13);
