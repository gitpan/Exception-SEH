use strict;

use Test::More tests => 28;
use Test::Exception;

use Exception::SEH;
no warnings;

throws_ok {eval 'try {} catch (Z) {} 1' or die $@} qr/no context var/;
throws_ok {eval 'try {} catch (Z where) {} 1' or die $@} qr/no context var/;
throws_ok {eval 'try {} catch (Z where {}) {} 1' or die $@} qr/no context var/;
throws_ok {eval 'try {} catch (X $e) {} catch (Z) {} 1' or die $@} qr/no context var/;
throws_ok {eval 'try {} catch (X $e) {} catch (Z where {}) {} 1' or die $@} qr/no context var/;

throws_ok {eval 'try {} catch (where Z) {} 1' or die $@} qr/must be followed by/;
throws_ok {eval 'try {} catch (Z $e where Z) {} 1' or die $@} qr/must be followed by/;
throws_ok {eval 'try {} catch (Z $e where) {} 1' or die $@} qr/must be followed by/;
throws_ok {eval 'try {} catch ($e where) {} 1' or die $@} qr/must be followed by/;
throws_ok {eval 'try {} catch ($e where) {} 1' or die $@} qr/must be followed by/;
throws_ok {eval 'try {} catch (X $e) {} catch (where Z) {} 1' or die $@} qr/must be followed by/;
throws_ok {eval 'try {} catch (X $e) {} catch (Z $e where Z) {} 1' or die $@} qr/must be followed by/;
throws_ok {eval 'try {} catch (X $e) {} catch (Z $e where) {} 1' or die $@} qr/must be followed by/;
throws_ok {eval 'try {} catch (X $e) {} catch ($e where) {} 1' or die $@} qr/must be followed by/;
throws_ok {eval 'try {} catch (X $e) {} catch ($e where) {} 1' or die $@} qr/must be followed by/;

throws_ok {eval 'try {} catch ($e wtf) {} 1' or die $@} qr/junk inside catch/;
throws_ok {eval 'try {} catch (X $e) {} catch ($e wtf) {} 1' or die $@} qr/junk inside catch/;
throws_ok {eval 'try {} catch ($ where) {} 1' or die $@} qr/junk inside catch/;
throws_ok {eval 'try {} catch ($) {} 1' or die $@} qr/junk inside catch/;

#throws_ok {eval 'try {} catch {} finally; 1' or die $@} qr/Code block expected/;
#throws_ok {eval 'try {} catch ($e); 1' or die $@} qr/Code block expected/;
#throws_ok {eval 'try {} catch; 1' or die $@} qr/Code block expected/;
#throws_ok {eval 'try {} catch {} catch; 1' or die $@} qr/Code block expected/;
#throws_ok {eval 'try {} catch {} catch ($e); 1' or die $@} qr/Code block expected/;
dies_ok {eval 'try {} catch {} finally; 1' or die $@};
dies_ok {eval 'try {} catch ($e); 1' or die $@};
dies_ok {eval 'try {} catch; 1' or die $@};
dies_ok {eval 'try {} catch {} catch; 1' or die $@};
dies_ok {eval 'try {} catch {} catch ($e); 1' or die $@};

throws_ok {eval 'try {} catch ($e) finally; 1' or die $@} qr/Code block expected/;
throws_ok {eval 'try () {}; 1' or die $@} qr/Code block expected/;
throws_ok {eval 'try; 1' or die $@} qr/Code block expected/;

throws_ok {eval 'try {} catch ({}' or die $@} qr/Unbalanced text supplied/;

