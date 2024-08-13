#!/usr/bin/perl



use DBI::Mock;
use DBI::Test::DSN::Provider;

use DBI::Test::Case::basic::disconnect;

my $test_case_conf = DBI::Test::DSN::Provider->get_dsn_creds("DBI::Test::Case::basic::disconnect", ['dbi:DBM:',undef,undef,{}]);
DBI::Test::Case::basic::disconnect->run_test($test_case_conf);

