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

	} catch (Z $e where { $_->{'value'} > 10 }){
		$foo = 15;

	} catch (X $e){
		$foo = 14;

	} catch (Z $e){
		$foo = 16;

	} catch ($e){
		$foo = 17;
	}
}

$foo = 10;
lives_ok { _t1(0) };
is($foo, 13);

$foo = 10;
lives_ok { _t1(bless {}, 'X') };
is($foo, 14);

$foo = 10;
lives_ok { _t1(bless {value => 16}, 'Z') };
is($foo, 15);

$foo = 10;
lives_ok { _t1(bless {value => 8}, 'Z') };
is($foo, 16);

$foo = 10;
lives_ok { _t1(bless {}, 'Y') };
is($foo, 17);

$foo = 10;
lives_ok { _t1('dead') };
is($foo, 17);
