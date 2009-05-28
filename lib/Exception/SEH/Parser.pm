#!/usr/bin/perl
package Exception::SEH::Parser;

use strict;
use Devel::Declare ();
use B::Hooks::EndOfScope;
use B::Hooks::OP::PPAddr;

sub DEBUG() { 0 }

sub INITIAL()	{ -1 }
sub TRY()		{ 0 }
sub CATCH()		{ 1 }
sub FINALLY()	{ 2 }

sub new{
	my ($class, $offset) = @_;

	print STDERR "new called at $offset\r\n" if DEBUG;
	bless {
		offset	=> $offset,
	}, shift;
}

#token manip

sub skip_word{
	my $self = shift;

	print STDERR "skip_word called at $self->{offset}\r\n" if DEBUG;

	if (my $len = Devel::Declare::toke_scan_word($self->{'offset'}, 1)) {
		$self->{'offset'} += $len;
	}
}

sub get_word{
	my $self = shift;

	print STDERR "get_word called at $self->{offset}\r\n" if DEBUG;

	if (my $len = Devel::Declare::toke_scan_word($self->{'offset'}, 1)) {
		return substr(Devel::Declare::get_linestr(), $self->{'offset'}, $len);
	}
	return '';
}

sub skip_spaces{
	my $self = shift;

	print STDERR "skip_spaces called at $self->{offset}\r\n" if DEBUG;

	$self->{'offset'} += Devel::Declare::toke_skipspace($self->{'offset'});
}

sub get_symbols{
	my ($self, $len) = @_;

	print STDERR "get_symbols called at $self->{offset} for $len\r\n" if DEBUG;

	return substr(Devel::Declare::get_linestr(), $self->{'offset'}, $len);
}


sub extract_args{
	my $self = shift;

	print STDERR "extract_args called at $self->{offset}\r\n" if DEBUG;

	my $linestr = Devel::Declare::get_linestr();
	if (substr($linestr, $self->{'offset'}, 1) eq '(') {
		my $length = Devel::Declare::toke_scan_str($self->{'offset'});
		my $proto = Devel::Declare::get_lex_stuff();
		Devel::Declare::clear_lex_stuff();

		$linestr = Devel::Declare::get_linestr();
		if (
			$length < 0
				||
			$self->{'offset'} + $length > length($linestr)
		){
			require Carp;
			Carp::croak "Unbalanced text supplied as catch argument";
		}
		substr($linestr, $self->{'offset'}, $length) = '';
		Devel::Declare::set_linestr($linestr);

		return $proto;
	}
	return '';
}

#injectors

sub inject{
	my ($self, $inject) = @_;

	print STDERR "inject called at $self->{offset} for '$inject'\r\n" if DEBUG;

	my $linestr = Devel::Declare::get_linestr;
	if ($self->{'offset'} > length($linestr)){
		require Carp;
		Carp::croak "Parser tried to inject data outside program source, stopping";
	}
	substr($linestr, $self->{'offset'}, 0) = $inject;
	Devel::Declare::set_linestr($linestr);

	$self->{'offset'} += length($inject);
}

sub inject_if_block{
	my ($self, $inject) = @_;

	print STDERR "inject_if_block called at $self->{offset} for '$inject'\r\n" if DEBUG;

	if ($self->get_symbols(1) eq '{'){
		$self->{'offset'} += 1;
		$self->inject($inject);
	}else{
		require Carp;
		Carp::croak 'Code block expected';
	}
}

sub get_semicolomn_injector{
	#my ($self, $call_type) = @_;
	return " BEGIN { Exception::SEH::Parser::semicolomn_injector($_[1]) }; ";
}

sub semicolomn_injector{
	my $call_type = shift;

	#checks syntax, and, if there's no more catch/finally
	#	put semicolon
	on_scope_end {
		if (
			$Exception::SEH::return_hook_id
				&&
			--$Exception::SEH::Parser::hook_nested_level <= 0
		){
			Exception::SEH::XS::uninstall_return_op_check($Exception::SEH::return_hook_id);
			$Exception::SEH::return_hook_id = undef;
		}

		my $parser = Exception::SEH::Parser->new(Devel::Declare::get_linestr_offset);

		print STDERR "on_scope_end for $call_type, current state $Exception::SEH::parser_state\r\n" if DEBUG;

		if ($call_type > 0){
			$parser->inject(')');
			$Exception::SEH::parse_catch_called = 1;
		}

		my $before = Devel::Declare::get_linestr();
		$parser->skip_spaces;
		my $after = Devel::Declare::get_linestr();
		if ($parser->get_symbols(5) ne 'catch' && $parser->get_symbols(7) ne 'finally'){
			if ($Exception::SEH::parser_state != INITIAL){
				print STDERR "End-of-try called in inapropriate parser state.\r\n Here we can't die normally - you won't get normal parse error.\r\n";
				exit -1;
			}

			#end-of-block
			if (
				($before ne $after)
					&&
				$Exception::SEH::parse_catch_called
			){
#				print STDERR "match\n";
				$parser->inject('));');
			}else{
				$parser->inject(');');
			}

			$Exception::SEH::parse_catch_called = 0;
			$Exception::SEH::parser_state = INITIAL;
		}else{
			$parser->inject(',');
			$Exception::SEH::parser_state = $call_type;
		}
		print STDERR "line after on_scope_end =", Devel::Declare::get_linestr(), "=\r\n" if DEBUG;
	}
}

1;

=head1

Copyright (c) 2009 by Sergey Aleynikov.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
