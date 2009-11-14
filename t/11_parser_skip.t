use strict;
use Test::More tests => 13;
use Test::Exception;
no warnings;

package Z;
	sub try{
		return 12;
	}

	sub catch{
		return 13;
	}

	sub finally{
		return 14;
	}

	sub new{
		bless {}, shift
	}

package main;
use Exception::SEH;

lives_and{ is((eval 'Z->try()' or die $@), 12) };
lives_and{ is((eval 'Z->catch()' or die $@), 13) };
lives_and{ is((eval 'Z->finally()' or die $@), 14) };

my $z;
lives_ok{ eval '$z = Z->new()' or die $@ };

lives_and{ is((eval '$z->try()' or die $@), 12) };
lives_and{ is((eval '$z->catch()' or die $@), 13) };
lives_and{ is((eval '$z->finally()' or die $@), 14) };

lives_and{ is((eval '$z->try' or die $@), 12) };
lives_and{ is((eval '$z->catch' or die $@), 13) };
lives_and{ is((eval '$z->finally' or die $@), 14) };

lives_ok{ eval 'try => 1' or die $@ };
lives_ok{ eval 'catch => 1' or die $@ };
lives_ok{ eval 'finally => 1' or die $@ };
