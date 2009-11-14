#!/usr/bin/perl
package Exception::SEH;

use strict;
use 5.008001;

use Carp ();
use Devel::Declare ();
use B::Hooks::EndOfScope;
use Exception::SEH::Parser;
use Scalar::Util qw(blessed);
use Scope::Upper qw(unwind want_at reap :words);

use XSLoader;

BEGIN{
	no strict 'refs';
	foreach (qw(INITIAL TRY CATCH FINALLY DEBUG)) {
		*{'Exception::SEH::'.$_} = *{'Exception::SEH::Parser::'.$_};
	}
}

our $VERSION = '0.02';
$Carp::Internal{'Exception::SEH'}++;
$Carp::Internal{'Devel::Declare'}++;

our %OPTS = ();
our $params = [];
our $need_unwind = 0;
our $hook_nested_level = 0;
our $parse_catch_called = 0;
our $return_hook_id = undef;

XSLoader::load(__PACKAGE__, $VERSION);

sub import{
	my $class = shift;
	my $caller = caller;

	my $cur_opts = $OPTS{$caller} = {
		-nosig	 => 0,
		-noret	 => 0,
		-safetry => 0,
	};

	foreach (@_) {
		if (exists $cur_opts->{$_}){
			$cur_opts->{$_} = 1;
		}else{
			Carp::croak "Tried to set non-existent option: $_";
		}
	}

	#try
	Devel::Declare->setup_for(
		$caller,
		{ try => { const => \&parse_try } }
	);

	no strict 'refs';

	#this'd be shadowed
	*{$caller.'::try'} = \&try;

	#these are never directly called
	*{$caller.'::finally'}	= sub (;&) { Carp::croak 'Found finally without a try{} block' };
	*{$caller.'::catch'}	= sub (;&) { Carp::croak 'Found catch without a try{} block' };
}

sub parse_try{
	my $parser = Exception::SEH::Parser->new($_[1]);

	if ((my $token = $parser->get_word()) ne 'try'){
		return;
	}

	$parser->skip_word();
	$parser->skip_spaces();
	if ($parser->get_symbols(2) eq '=>'){
		return;
	}

	$parser->inject('(\@_, sub');

	$return_hook_id = Exception::SEH::XS::install_return_op_check()
		if !$OPTS{Devel::Declare::get_curstash_name}->{'-noret'} && !$return_hook_id;
	$hook_nested_level++;

	$parser->inject_if_block($parser->get_injector('Exception::SEH::aftercheck', TRY));
	$parser->inject('*_ = $Exception::SEH::params;');
}

sub aftercheck{
	my $prev_item_type = shift;

	on_scope_end {
		if (
			$return_hook_id
				&&
			--$hook_nested_level <= 0
		){
			Exception::SEH::XS::uninstall_return_op_check($return_hook_id);
			$return_hook_id = undef;
		}

		my $parser = Exception::SEH::Parser->new(Devel::Declare::get_linestr_offset);

		$parser->skip_spaces();
		my $token = $parser->get_word();

		if ($token eq 'catch'){
			parse_catch($parser, $prev_item_type);
		}elsif ($token eq 'finally'){
			parse_finally($parser, $prev_item_type);
		}else{
			$parser->inject(');');
		}
	}
}

sub parse_finally{
	my ($parser, $prev_item_type) = @_;

	if ($prev_item_type == FINALLY){
		$parser->panic('Found finally block more than once after single try{}');
	}

	$parser->cutoff(length('finally'));
	$parser->inject(', sub ');
	$parser->skip_spaces();
	$parser->inject_if_block($parser->get_injector('Exception::SEH::aftercheck', FINALLY));
}

sub parse_catch{
	my ($parser, $prev_item_type) = @_;

	if ($prev_item_type == FINALLY){
		$parser->panic('Found catch block again after finally');
	}

	$parser->cutoff(length('catch'));
	$parser->inject(', ');
	$parser->skip_spaces();

	my $err_var = undef;

	if ($parser->get_symbols(1) eq '('){
		my $args = $parser->extract_args();

		if (length($args)){
			my ($type) = $args =~ /\G\s*(?!where\W)([a-zA-Z0-9_:]+)\s*/gcs;
			($err_var) = $args =~ /\G\s*\$(\w+)\s*/gcs;

			if ($type && !$err_var){
				$parser->panic("Found exception class definition, but no context var while parsing catch definition");
			}

			if ($type){
				$parser->inject(" '$type', ");
			}else{
				$parser->inject(" undef, ");
			}

			my ($where_present, $where) = $args =~ /\G\s*(where)\s*(.*?)\s*$/gcs;
			if ($where_present && $where !~ /^{.*}$/){
				$parser->panic('"Where" must be followed by a block inside catch definition');
			}

			if ($where){
				$parser->inject(" sub $where");
			}else{
				$parser->inject(" undef");
			}

			if (pos($args) != length($args)){
				$parser->panic('Found junk inside catch definition');
			}

		}else{
			$parser->inject(' undef, undef');
		}

	}else{
		$parser->inject(' undef, undef');
	}

	$parser->inject(', sub ');
	$return_hook_id = Exception::SEH::XS::install_return_op_check()
		if !$OPTS{Devel::Declare::get_curstash_name}->{'-noret'} && !$return_hook_id;
	$hook_nested_level++;

	$parser->skip_spaces();
	$parser->inject_if_block($parser->get_injector('Exception::SEH::aftercheck', CATCH));
	$parser->inject('my $'.$err_var.' = $@;') if $err_var;
}

#==========##==========##==========#

sub try($&@) {
	my $opts = $OPTS{scalar caller};
	local $SIG{__DIE__} = 'DEFAULT' if $opts->{'-nosig'};

	#for unwind
	my $is_top_try = 0;

	if (!defined(EVAL) || EVAL != CALLER 2){	#we're inside top try
		$is_top_try = 1;
	}
	local $params = shift;
	my $code = shift;

	my $finally = (scalar @_ % 3 == 0 ? undef : pop @_);
	my $catch_fail = 0;
	my $exception_caught = 1;

	my $cx = $is_top_try ? UP SUB : EVAL;
	my $context = $opts->{'-noret'} ? wantarray : want_at($cx);

	$@ = undef;
	my @result;
	if ($context){
		@result = eval { $code->() }
	}elsif(defined($context)){
		$result[0] = eval { $code->() }
	}else{
		eval { $code->() }
	}

	my $err = $@;
	$exception_caught = 0 if $err;

	if ($err && scalar @_){
		my $checked = 0;

		eval{
			my $err_blessed = blessed($err);

			my $pos = -3;
			while ($pos + 3 < scalar @_) {
				$pos += 3;
				my ($type, $where, $handler) = @_[$pos..$pos+2];

				if (
					!$type
						||
					 $err_blessed
						&&
					$err->isa($type)
				){
					if (defined $where){
						local $_ = $err;
						next if !$where->();
					}

					$exception_caught = 1;
					my $_need_unwind = $need_unwind;
					$need_unwind = 0;
					my @_result;

					eval {
						$@ = $err;
						if ($context){
							@_result = $handler->(@$params);
						} elsif (defined($context)) {
							$_result[0] = $handler->(@$params);
						} else {
							$handler->(@$params);
						};
						1;
					} or do {
						$err = $@;
						$catch_fail = 1;
					};

					if ($need_unwind){
						@result = @_result;
					}else{
						$need_unwind = $_need_unwind;
					}
					last;
				}
			}
			1;
		} or do {
			$err = $@;
			$catch_fail = 1;
		}
	}

	if (defined $finally){
		$@ = $err;
		$finally->(@$params);
	}

	if ($catch_fail || (!$exception_caught && !$opts->{'-safetry'})){
		local $SIG{__DIE__} = 'DEFAULT';
		die $err;
	}

	if($opts->{'-noret'} || !$need_unwind){
		#print STDERR "normal return\n";
		$need_unwind = 0;
		return wantarray ? @result : $result[0];

	}elsif($need_unwind){
		$need_unwind = 0 if $is_top_try;
		unwind +($context ? @result : $result[0]) => $cx;

	}else{
		Carp::croak 'Cannot determine return point';
	}
}

1;

=head1

Copyright (c) 2009 by Sergey Aleynikov.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
