use strict;
use Test::More tests => 3;
use Test::Exception;

use Exception::SEH;

throws_ok {eval q/
	try{
	} finally {
	}

	try{
	} finally {
	} finally {
	}
/; die $@ if $@ } qr/Found finally block more than once/;

throws_ok {eval q/
	try{
		try{
		} catch {
		}
	} finally {
	} finally {
	}

/; die $@ if $@} qr/Found finally block more than once/;

throws_ok {eval q/
	try{
		try{
		} finally {
		} finally {
		}
	} catch {
	}

/; die $@ if $@} qr/Found finally block more than once/;

