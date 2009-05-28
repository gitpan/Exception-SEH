use strict;
use Test::More tests => 15;
use Test::Exception;

use Exception::SEH;

lives_ok {eval q/
	try{
		try{
		}
	}

	1;
/ or die $@};

lives_ok {eval q/
	try{
		try{
		} catch {
		}
	}

	1;
/ or die $@};

lives_ok {eval q/
	try{
		try{
		} finally {
		}
	}

	1;
/ or die $@};

lives_ok {eval q/
	try{
		try{
		}
	} catch {
	}

	1;
/ or die $@};

lives_ok {eval q/
	try{
		try{
		} catch {
		}
	} finally {
	}

	1;
/ or die $@};

lives_ok {eval q/
	try{
		try{
		} finally {
		}
	} finally {
	}

	1;
/ or die $@};

lives_ok {eval q/
	try{
	}

	try{
	}

	1;
/ or die $@};

lives_ok {eval q/
	try{
	} catch {
	}

	try{
	} catch {
	}

	1;
/ or die $@};

lives_ok {eval q/
	try{
	} catch {
		try{
		} catch {
		}
	}

	1;
/ or die $@};

lives_ok {eval q/
	try{
	} finally {
		try{
		} catch {
		} finally {
		}
	}

	1;
/ or die $@};

lives_ok {eval q/
	try{

	}catch ($e) {
		try{
		} catch ($e) {
		}	my $a = 1
	}

	1;
/ or die $@};

lives_ok {eval q/
	try{

	}catch ($e) {
		try{
		} catch ($e) {
		}
		my $a = 1
	}

	1;
/ or die $@};

lives_ok {eval q/
	try{

	}catch ($e) {
		try{
		} catch ($e) {
		}	my $a = 1
	} my $a = 1;

	1;
/ or die $@};

lives_ok {eval q/
	try{

	}catch ($e) {
		try{
		} catch ($e) {
		}	my $a = 1
	}
	my $a = 1;

	1;
/ or die $@};

lives_ok { eval q/
	try{
	} finally {
	}

	try{
		try{
		} finally {
		}
	} finally {
	}
/; die $@ if $@};
