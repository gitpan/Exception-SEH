use strict;
use Test::More tests => 6;
use Test::Exception;

use Exception::SEH;

#throws_ok {eval 'catch {} 1' or die $@} qr/catch without a try/;
#throws_ok {eval 'finally {} 1' or die $@} qr/finally without a try/;

#throws_ok {eval 'try {} 1 && catch {} 1' or die $@} qr/catch without a try/;
#throws_ok {eval 'try {} 1 and catch {} 1' or die $@} qr/catch without a try/;

#throws_ok {eval 'try {} catch {} 1 && finally {} 1' or die $@} qr/finally without a try/;
#throws_ok {eval 'try {} catch {} 1 and finally {} 1' or die $@} qr/finally without a try/;

dies_ok {eval 'catch {} 1' or die $@};
dies_ok {eval 'finally {} 1' or die $@};

dies_ok {eval 'try {} 1 && catch {} 1' or die $@};
dies_ok {eval 'try {} 1 and catch {} 1' or die $@};

dies_ok {eval 'try {} catch {} 1 && finally {} 1' or die $@};
dies_ok {eval 'try {} catch {} 1 and finally {} 1' or die $@};
