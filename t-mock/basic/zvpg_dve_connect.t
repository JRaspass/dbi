#!/usr/bin/perl

BEGIN {
$ENV{DBI_PUREPERL} = 2;
$ENV{DBI_AUTOPROXY} = 'dbi:Gofer:transport=null;policy=pedantic'
}

END {
delete $ENV{DBI_PUREPERL};;
delete $ENV{DBI_AUTOPROXY};
}

use DBI::Mock;
use DBI::Test::DSN::Provider;

use DBI::Test::Case::basic::connect;

my $test_case_conf = DBI::Test::DSN::Provider->get_dsn_creds("DBI::Test::Case::basic::connect", ['dbi:ExampleP:',undef,undef,{}]);
DBI::Test::Case::basic::connect->run_test($test_case_conf);

