use strict;
use Test::More tests => 12;
use Test::Exception;

use Exception::SEH;

my $foo;
sub _t1{
	my $todie = shift;

	try{
		$foo = 12;
		die $todie if $todie;
		$foo = 13;

	} catch (Z $e where { die 'sadbadtrue' }){
		$foo = 14;

	} catch (X $e where { die 'vinny' }){
		$foo = 14;

	} catch ($e){
		$foo = 14;
		die 'undead' if $todie =~ /dead/;

	} finally {
		die 'pooh' if $@ =~ /vinny/;
		$foo = 15;
	}
}

$foo = 10;
lives_ok { _t1(0) };
is($foo, 15);

$foo = 10;
lives_ok { _t1(1) };
is($foo, 15);

$foo = 10;
throws_ok { _t1('dead') } qr/undead/;
is($foo, 15);

$foo = 10;
throws_ok { _t1('vinny') } qr/pooh/;
is($foo, 14);

$foo = 10;
throws_ok { _t1(bless {}, 'Z') } qr/sadbadtrue/;
is($foo, 15);


$foo = 10;
throws_ok { _t1(bless {}, 'X') } qr/pooh/;
is($foo, 12);

