use strict;
use Test::More tests => 4;
use Test::Exception;

{
	package Test1;
	use Exception::SEH;

	our $foo;
	sub _t1{
		my $todie = shift;

		try{
			$foo = 11;
			die $todie if $todie;
		}
		$foo = 12;
	}

}
{
	package Test2;
	use Exception::SEH -safetry;

	our $foo;
	sub _t1{
		my $todie = shift;

		try{
			$foo = 11;
			die $todie if $todie;
		}
		$foo = 12;
	}
}

$Test1::foo = 10;
throws_ok { Test1::_t1('dead')  } qr/dead/;
is($Test1::foo, 11);

$Test2::foo = 10;
lives_ok { Test2::_t1('dead')  };
is($Test2::foo, 12);

