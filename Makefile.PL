use strict;
use inc::Module::Install;

perl_version '5.008001';
name 'Exception-SEH';

abstract_from 'lib/Exception/SEH.pod';
author 'Sergey Aleynikov <sergey.aleynikov@gmail.com>';
version_from 'lib/Exception/SEH.pm';
license 'perl';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::Warn';

configure_requires 'B::Hooks::OP::PPAddr' => '0.02';
configure_requires 'B::Hooks::OP::Check' => '0.15';
configure_requires 'ExtUtils::Depends';

requires 'Carp';
requires 'XSLoader';
requires 'Scalar::Util';
requires 'Scope::Upper' => '0.07';
requires 'Devel::Declare' => '0.005';
requires 'B::Hooks::EndOfScope' => '0.08';

eval 'require ExtUtils::Depends' or die 'You must install ExtUtils::Depends, B::Hooks::OP::PPAddr, B::Hooks::OP::Check before running install';
my $pkg = ExtUtils::Depends->new('TryCatch', 'B::Hooks::OP::PPAddr', 'B::Hooks::OP::Check');
makemaker_args(
    $pkg->get_makefile_vars,
);

system 'pod2text lib/Exception/SEH.pod > README';

WriteAll;
