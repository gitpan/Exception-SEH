use strict;
use Test::More tests => 4;
use Test::Exception;

use Exception::SEH;

my $foo;
sub _t1{
	try{
		return _t2(shift);
	}finally{
		$foo = 15;
	}
}

sub _t2{
	try{
		return 16 if shift;
		die 'unreal';
	}catch (where { $_ =~ /unreal/ }) {
		return 17;
	}
}

$foo = 10;
is(_t1(1), 16);
is($foo, 15);

$foo = 10;
is(_t1(0), 17);
is($foo, 15);
