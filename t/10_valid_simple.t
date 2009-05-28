use strict;
use Test::Exception tests => 19;

use Exception::SEH;

lives_ok{
	eval 'try{} 1' or die $@;
};

lives_ok{
	eval 'try{}catch{} 1' or die $@;
};

lives_ok{
	eval 'try{} catch{} 1' or die $@;
};

lives_ok{
	eval 'try{} catch(){} 1' or die $@;
};

lives_ok{
	eval 'try{} catch (){} 1' or die $@;
};

lives_ok{
	eval 'try{} catch ($e){} 1' or die $@;
};

lives_ok{
	eval 'try{} catch ($e){ $e++ } 1' or die $@;
};

lives_ok{
	eval 'try{} catch (Z $e){} 1' or die $@;
};

lives_ok{
	eval 'try{} catch (Z $e){ $e++ } 1' or die $@;
};

lives_ok{
	eval 'try{} catch (where {$_}){} 1' or die $@;
};

lives_ok{
	eval 'try{} catch (Z $e where {$_}){} 1' or die $@;
};

lives_ok{
	eval 'try{} catch (Z $e where {$_}){ $e++ } 1' or die $@;
};

lives_ok{
	eval 'try{} catch (Z $e){} catch {} 1' or die $@;
};

lives_ok{
	eval 'try{} catch {} finally{} 1' or die $@;
};

lives_ok{
	eval 'try{} catch {}finally{} 1' or die $@;
};

lives_ok{
	eval 'try{} catch (Z $e) {} catch {} finally{} 1' or die $@;
};

lives_ok{
	eval <<EOF;
		try{}
EOF
die $@ if $@;
};

lives_ok{
	eval <<EOF;
		try{
		}catch{
		}
EOF
die $@ if $@;
};

lives_ok{
	eval <<EOF;
		try{}catch{}
EOF
die $@ if $@;
};
