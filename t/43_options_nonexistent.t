use strict;
use Test::More tests => 1;
use Test::Exception;


throws_ok { eval q/
	{
		package Test1;
		use Exception::SEH -wrong;
	}
/; die $@ if $@ } qr/non-existent option/;
