use strict;
use Test::More tests => 1;

use Exception::SEH -noret;

sub _t1{
	try{
		return 18;
	}
	return 11;
}

is (_t1(), 11);
