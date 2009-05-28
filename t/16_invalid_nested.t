use strict;
use Test::More tests => 6;
use Test::Exception;

use Exception::SEH;

throws_ok {eval q/
	try{
		catch {};
	}

	1;
/ or die $@} qr/catch without a try/;

throws_ok {eval q/
	try{
		finally {};
	}

	1;
/ or die $@} qr/finally without a try/;

throws_ok {eval q/
	try{
		try {
		};
		finally {};
	}

	1;
/ or die $@} qr/finally without a try/;

throws_ok {eval q/
	try{
	}catch{
		try;
	}

	1;
/ or die $@} qr/Code block expected/;

throws_ok {eval q/
	try{
	}catch{
		try{
		};
		catch;
	}

	1;
/ or die $@} qr/catch without a try/;

throws_ok {eval q/
	try{
	}catch{
		catch;
	}

	1;
/ or die $@} qr/catch without a try/;

