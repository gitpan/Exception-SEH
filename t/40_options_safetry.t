use strict;
use Test::More tests => 2;
use Test::Exception;

use Exception::SEH -safetry;

my $foo;
sub _t1{
	my $todie = shift;

	try{
		$foo = 11;
		die $todie if $todie;
	}
	$foo = 12;
}

$foo = 10;
lives_ok { _t1(1)  };
is($foo, 12);
