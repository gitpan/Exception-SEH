#!/usr/bin/perl
package Exception::SEH;

use 5.008001;

use strict;
use Devel::Declare ();
use Exception::SEH::Parser;
use Scalar::Util qw(blessed);
use Scope::Upper qw/unwind want_at :words/;

use XSLoader;

BEGIN{
	no strict 'refs';
	foreach (qw(INITIAL TRY CATCH FINALLY DEBUG)) {
		*{'Exception::SEH::'.$_} = *{'Exception::SEH::Parser::'.$_};
	}
}

our $VERSION = '0.01001';
$Carp::Internal{'Exception::SEH'}++;
$Carp::Internal{'Devel::Declare'}++;

our $parser_state = INITIAL;
our %OPTS = ();
our $params;
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
			require Carp;
			Carp::croak "Tryed to set non-existent option: $_";
		}
	}

	no strict 'refs';

	#try
	Devel::Declare->setup_for(
		$caller,
		{ try => { const => \&parse_try } }
	);
	*{$caller.'::try'} = \&try;

	#catch
	Devel::Declare->setup_for(
		$caller,
		{ catch => { const => \&parse_catch } }
	);
	*{$caller.'::catch'} = \&catch;

	#finally
	Devel::Declare->setup_for(
		$caller,
		{ finally => { const => \&parse_finally } }
	);
	*{$caller.'::finally'} = \&finally;
}

# result: [code, CATCH | FINALLY, type, check]

sub catch($&&) {
	return [$_[2], CATCH, $_[0], $_[1]];
}

sub finally(&) {
	return [$_[0], FINALLY]
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

	$Exception::SEH::return_hook_id = Exception::SEH::XS::install_return_op_check()
		if !$OPTS{scalar caller(1)}->{'-noret'} && !$Exception::SEH::return_hook_id;
	$Exception::SEH::Parser::hook_nested_level++;

	$parser->inject_if_block($parser->get_semicolomn_injector(TRY));
	$parser->inject('*_ = $Exception::SEH::params;');
	$Exception::SEH::parser_state = INITIAL;
}


sub parse_finally{
	my $parser = Exception::SEH::Parser->new($_[1]);

	if ((my $token = $parser->get_word()) ne 'finally'){
		return;
	}

	$parser->skip_word();
	$parser->skip_spaces();
	if ($parser->get_symbols(2) eq '=>'){
		return;
	}

	if ($Exception::SEH::parser_state == INITIAL){
		require Carp;
		Carp::croak 'Found finally without a try{} block';
	}

	if ($Exception::SEH::parser_state == FINALLY){
		require Carp;
		Carp::croak 'Found finally block more than once after single try{}';
	}

	$parser->inject('(sub');
	$parser->inject_if_block($parser->get_semicolomn_injector(FINALLY));
	$Exception::SEH::parser_state = INITIAL;
}

sub parse_catch{
	my $parser = Exception::SEH::Parser->new($_[1]);

	if ((my $token = $parser->get_word()) ne 'catch'){
		return;
	}

	$parser->skip_word();
	$parser->skip_spaces();
	if ($parser->get_symbols(2) eq '=>'){
		return;
	}

	if ($Exception::SEH::parser_state == INITIAL){
		require Carp;
		Carp::croak 'Found catch without a try{} block';
	}

	my $err_var = undef;
	$parser->inject('(');

	if ($parser->get_symbols(1) eq '('){
		my $args = $parser->extract_args();

		if (length($args)){
			my ($type) = $args =~ /\G\s*(?!where\W)([a-zA-Z0-9_:]+)\s*/gcs;
			($err_var) = $args =~ /\G\s*\$(\w+)\s*/gcs;

			if ($type && !$err_var){
				require Carp;
				Carp::croak "Found exception class definition, but no context var while parsing catch definition";
			}

			if ($type){
				$parser->inject(" '$type',");
			}else{
				$parser->inject(" undef,");
			}

			my ($where_present, $where) = $args =~ /\G\s*(where)\s*(.*?)\s*$/gcs;
			if ($where_present && $where !~ /^{.*}$/){
				require Carp;
				Carp::croak '"Where" must be followed by a block inside catch definition';
			}

			if ($where){
				$parser->inject(" sub $where, sub");
			}else{
				$parser->inject(" undef, sub");
			}

			if (pos($args) != length($args)){
				require Carp;
				Carp::croak 'Found junk inside catch definition';
			}

		}else{
			$parser->inject(' undef, undef, sub');
		}

	}else{
		$parser->inject(' undef, undef, sub');
	}

	$parser->skip_spaces();
	$Exception::SEH::return_hook_id = Exception::SEH::XS::install_return_op_check()
		if !$OPTS{scalar caller(1)}->{'-noret'} && !$Exception::SEH::return_hook_id;
	$Exception::SEH::Parser::hook_nested_level++;

	$parser->inject_if_block($parser->get_semicolomn_injector(CATCH));
	$parser->inject('my $'.$err_var.' = $@;') if $err_var;
	$Exception::SEH::parser_state = INITIAL;
}

#==========##==========##==========#

sub try($&@) {
	my $opts = $OPTS{scalar caller()};
	local $SIG{__DIE__} = 'DEFAULT' if $opts->{'-nosig'};

	#for unwind
	my $is_top_try = 0;

	if (!defined(EVAL) || EVAL != CALLER 2){	#we're inside top try
		$is_top_try = 1;
	}
	local $params = shift;
	my $code = shift;
	my $finally = undef;
	if (scalar @_ && $_[$#_]->[1] == FINALLY){
		$finally = pop @_;
	}
	my $catch_fail = 0;
	my $exception_caught = 1;

	my $cx = $is_top_try ? UP SUB : EVAL;
	my $context = $opts->{'-noret'} ? wantarray : want_at($cx);

	$@ = undef;
	my @result;
	if ($context){
		@result = eval {
			$code->();
		};

	}elsif(defined($context)){
		$result[0] = eval {
			$code->();
		};

	}else{
		eval {
			$code->();
		};
	}

	my $err = $@;
	$exception_caught = 0 if $err;

	if ($err && scalar @_){
		my $checked = 0;

		eval{
			my $err_blessed = blessed($err);

			foreach my $handler (@_) {
				next if $handler->[1] != CATCH;

				if (
					!$handler->[2]
						||
					 $err_blessed
						&&
					$err->isa($handler->[2])
				){
					if ($handler->[3]){
						local $_ = $err;
						next if !$handler->[3]->();
					}

					$exception_caught = 1;
					my $_need_unwind = $need_unwind;
					$need_unwind = 0;
					my @_result;

					if ($context){
						@_result = eval {
							$@ = $err;
							$handler->[0]->();
						};

					}elsif(defined($context)){
						$_result[0] = eval {
							$@ = $err;
							$handler->[0]->();
						};

					}else{
						eval {
							$@ = $err;
							$handler->[0]->();
						};
					}

					if ($@){
						$err = $@;
						$catch_fail = 1;
					}

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

	if ($finally){
		#let it die, if it can
		$@ = $err;
		$finally->[0]->();
	}

	if ($catch_fail || (!$exception_caught && !$opts->{'-safetry'})){
		local $SIG{__DIE__} = 'DEFAULT';
		die $err;
	}

	if($opts->{'-noret'} || !$need_unwind){
#		print STDERR "normal return\n";
		$need_unwind = 0;
		return wantarray ? @result : $result[0];

	}elsif($need_unwind){
		$need_unwind = 0 if $is_top_try;
		unwind +($context ? @result : $result[0]) => $cx;

	}else{
		require Carp;
		Carp::croak 'Cannot determine return point';
	}
}

1;

=head1

Copyright (c) 2009 by Sergey Aleynikov.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
