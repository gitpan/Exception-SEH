use strict;
use Test::More tests => 1;
use Test::Exception;

use Exception::SEH;

throws_ok {eval 'try {} finally {} finally {} 1' or die $@} qr/Found finally block more than once/;
