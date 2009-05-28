use strict;
use Test::More tests => 7;
use Test::Exception;
use Test::Warn;

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
	use Exception::SEH -nosig;

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
	my $i = 1;
	local $SIG{__DIE__} = sub { warn "caught$i"; $i++ };
	$Test1::foo = 10;
	warning_like {dies_ok { Test1::_t1('dead')  } } qr/caught1/;
	is($Test1::foo, 11);
}

{
	local $SIG{__DIE__} = sub { die 'pooh' };
	$Test1::foo = 10;
	throws_ok { Test1::_t1('dead')  } qr/pooh/;
	is($Test1::foo, 11);
}

{
	local $SIG{__DIE__} = sub { die 'pooh' };
	$Test2::foo = 10;
	throws_ok { Test2::_t1('dead')  } qr/dead/;
	is($Test2::foo, 11);
}

