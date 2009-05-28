use strict;
use Test::More tests => 8;
use Test::Exception;

use Exception::SEH;

sub _t1{
	try{
		return 12;
	}
	return 13;
}

is(_t1(), 12);

sub _t2{
	try{
		try{
			return 12 if shift;
		}
		return 13 if shift;
	}
	return 14;
}

is(_t2(1), 12);
is(_t2(0, 1), 13);
is(_t2(0, 0), 14);


sub _t3{
	try{
		try{
			die if shift;
		}catch{
			return 13;
		}
	}
	return 14;
}

is(_t3(0), 14);
is(_t3(1), 13);

sub _t4{
	try{
		my $i++;
	}
	return 13;
}

is(_t4(), 13);

sub _t5{
	try{
		try{
			my $i = 15;
		}
	}
}

is(_t5(), 15);

