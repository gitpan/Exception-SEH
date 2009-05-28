use strict;
use Test::More tests => 18;
use Test::Exception;

use Exception::SEH;

my $foo;
{
	sub _t1{
		my $todie = shift;

		try{
			$foo = 11;

			try {
				die $todie if $todie =~ /dead/;
				$foo = 12;
				die $todie if $todie;
			}
		} catch ($e where { $_ !~ /dead/ }){
			$foo = 13;
		} catch {
			$foo = 14;
		}
	}

	$foo = 10;
	lives_ok { _t1(0) };
	is($foo, 12);

	$foo = 10;
	lives_ok { _t1(1) };
	is($foo, 13);

	$foo = 10;
	lives_ok { _t1('dead') };
	is($foo, 14);
}

{
	sub _t2{
		my $todie = shift;

		try{
			$foo = 16;

			try {
				$foo = 17;
				die $todie if $todie;
			} catch ($e){
				$foo = 18;
				die $e if $e =~ /dead/;
			}

		} catch {
			$foo = 19;
		}
	}

	$foo = 10;
	lives_ok { _t2(0) };
	is($foo, 17);

	$foo = 10;
	lives_ok { _t2(1) };
	is($foo, 18);

	$foo = 10;
	lives_ok { _t2('dead') };
	is($foo, 19);
}

{
	sub _t3{
		my $todie = shift;

		my $skip = 0;
		try{
			$foo = 20;

			try {
				die "oops";
			} catch ($e){
				$foo = 22;
			} finally {
				die $todie if $todie;
				$foo = 23;
			}

		} catch (where { /dead/ } ){
			$skip = 1;
			$foo = 24;

		} finally {
			$foo = 25 if !$skip;
		}
	}

	$foo = 10;
	lives_ok { _t3(0) };
	is($foo, 25);

	$foo = 10;
	throws_ok { _t3('pooh') } qr/pooh/;
	is($foo, 25);

	$foo = 10;
	lives_ok { _t3('dead') };
	is($foo, 24);
}