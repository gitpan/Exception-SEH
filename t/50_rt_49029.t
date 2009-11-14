use strict;
use Test::More tests => 1;

use Exception::SEH;

my $ok = eval q/
	try {
		if (1) {
		} else {
			ab( } );
		}
	}

	1;
/;

#this can seem as strange test
# but this just to ensure that parsing this code
# does not crashes perl, but produces some error
# (they're different on different perls)

ok(!$ok);
