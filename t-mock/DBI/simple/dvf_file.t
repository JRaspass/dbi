#!/usr/bin/perl



use DBI::Mock;
use DBI::Test::DSN::Provider;

use DBI::Test::Case::DBI::simple::file;

my $test_case_conf = DBI::Test::DSN::Provider->get_dsn_creds("DBI::Test::Case::DBI::simple::file", ['dbi:File:',undef,undef,{}]);
DBI::Test::Case::DBI::simple::file->run_test($test_case_conf);

