#!/usr/bin/perl
package Exception::SEH::Parser;

use strict;

use Carp ();
use Devel::Declare ();
use B::Hooks::OP::PPAddr;
use Scope::Upper qw(EVAL);

sub DEBUG() { 0 }

sub INITIAL()	{ -1 }
sub TRY()		{ 0 }
sub CATCH()		{ 1 }
sub FINALLY()	{ 2 }

our $VERSION = '0.01003';

sub new{
	my ($class, $offset) = @_;

	print STDERR "new called at $offset\r\n" if DEBUG;
	bless {
		offset	=> $offset,
	}, $class;
}

#err handler

sub panic{
	my ($self, $err) = @_;

	if (EVAL > 0){
		Carp::croak $err;
	}else{
		print STDERR 'Exception::SEH - ', $err, "\n\n";
		die;
	}
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
				||
			$self->{'offset'} < 0
		){
			$self->panic("Unbalanced text supplied as catch argument");
		}
		substr($linestr, $self->{'offset'}, $length) = '';
		Devel::Declare::set_linestr($linestr);

		return $proto;
	}
	return '';
}

#injectors

sub inject{
	my ($self, $string) = @_;

	$self->substitute($string, 0);
}

sub cutoff{
	my ($self, $len) = @_;

	$self->substitute('', $len);
}

sub substitute{
	my ($self, $string, $replace_len) = @_;

	print STDERR "inject called at $self->{offset} for '$string'\r\n" if DEBUG;

	my $linestr = Devel::Declare::get_linestr;
	if (
		$self->{'offset'} > length($linestr)
				||
		$self->{'offset'} < 0
	){
		$self->panic("Parser tried to inject data outside program source, stopping");
	}
	substr($linestr, $self->{'offset'}, $replace_len) = $string;
	Devel::Declare::set_linestr($linestr);

	$self->{'offset'} += length($string);
}

sub inject_if_block{
	my ($self, $inject) = @_;

	print STDERR "inject_if_block called at $self->{offset} for '$inject'\r\n" if DEBUG;

	if ($self->get_symbols(1) eq '{'){
		$self->{'offset'} += 1;
		$self->inject($inject);
	}else{
		$self->panic('Code block expected');
	}
}

sub get_injector{
	my ($self, $func, @args) = @_;

	return " BEGIN { $func(".join(',', map { "'$_'" } @args).") } ";
}

1;

=head1 NAME

Exception::SEH::Parser - parses source for L<Exception::SEH> and is not intended for external use.

=head1 AUTHOR

Copyright (c) 2009 by Sergey Aleynikov.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
