use strict;
use Test::More tests => 6;
use Test::Exception;

use Exception::SEH;
my $foo;

sub _t1{
	try{
		shift;
		$_[0]++;
	}
}

$foo = 10;
lives_ok { _t1(15, $foo) };
is($foo, 11);

sub _t2{
	try{
		shift;
		try{
			shift;
			$_[0]++;
		}
	}
}

$foo = 16;
lives_ok { _t2(15, 15, $foo) };
is($foo, 17);

#use Data::Dumper;
sub _t3{
	try{
		shift;
		$_[1]++;
	}

#	warn Dumper(\@_);
	try{
		shift;
		$_[0]++;
	}
}

$foo = 20;
lives_ok { _t3(15, 15, $foo) };
is($foo, 22);
