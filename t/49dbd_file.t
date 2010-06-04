#!perl -w
$|=1;

use strict;

use Cwd;
use File::Path;
use File::Spec;
use Test::More;

my $using_dbd_gofer = ($ENV{DBI_AUTOPROXY}||'') =~ /^dbi:Gofer.*transport=/i;

#use DBI;

my $tbl;
BEGIN { $tbl = "db_". $$ . "_" };
#END   { $tbl and unlink glob "${tbl}*" }

use_ok ("DBI");
use_ok ("DBD::File");

my $dir = File::Spec->catdir(getcwd(),'test_output');

rmtree $dir;
mkpath $dir;

my $rowidx = 0;
my @rows = ( [ "Hello World" ], [ "Hello DBI Developers" ], );

my $dbh;

# Check if we can connect at all
ok ($dbh = DBI->connect ("dbi:File:"), "Connect clean");
is (ref $dbh, "DBI::db", "Can connect to DBD::File driver");

# Check if all the basic DBI attributes are accepted
ok ($dbh = DBI->connect ("dbi:File:", undef, undef, {
    RaiseError		=> 1,
    PrintError		=> 1,
    AutoCommit		=> 1,
    ChopBlanks		=> 1,
    ShowErrorStatement	=> 1,
    FetchHashKeyName	=> "NAME_lc",
    }), "Connect with DBI attributes");

# Check if all the f_ attributes are accepted, in two ways
ok ($dbh = DBI->connect ("dbi:File:f_ext=.txt;f_dir=.;f_encoding=cp1252;f_schema=test"), "Connect with driver attributes in DSN");

my $encoding = "iso-8859-1";

# now use dir to prove file existence
ok ($dbh = DBI->connect ("dbi:File:", undef, undef, {
    f_ext	=> ".txt",
    f_dir	=> $dir,
    f_schema	=> undef,
    f_encoding	=> $encoding,
    f_lock	=> 0,

    RaiseError	=> 0,
    PrintError	=> 0,
    }), "Connect with driver attributes in hash");

my $sth;
ok ($sth = $dbh->prepare ("select * from t_sbdgf_53442Gz"), "Prepare select from non-existing file");

{   my @msg;
    eval {
	local $SIG{__DIE__} = sub { push @msg, @_ };
	$sth->execute;
	};
    like ("@msg", qr{Cannot open .*/t_sbdgf_}, "Cannot open non-existing file");
    }

SKIP: {
    my $fh;
    my $tbl2 = $tbl . "2";

    my $tbl2_file1 = File::Spec->catfile ($dir, "$tbl2.txt");
    open $fh, ">", $tbl2_file1 or skip;
    print $fh "You cannot read this anyway ...";
    close $fh;

    my $tbl2_file2 = File::Spec->catfile ($dir, "$tbl2");
    open $fh, ">", $tbl2_file2 or skip;
    print $fh "Neither that";
    close $fh;

    ok ($dbh->do ("drop table if exists $tbl2"), "drop manually created table $tbl2 (first file)");
    ok (! -f $tbl2_file1, "$tbl2_file1 removed");
    ok (-f $tbl2_file2, "$tbl2_file2 exists");
    ok ($dbh->do ("drop table if exists $tbl2"), "drop manually created table $tbl2 (second file)");
    ok (! -f $tbl2_file2, "$tbl2_file2 removed");
    }

my @tfhl;

# Now test some basic SQL statements
my $tbl_file = File::Spec->catfile ($dir, "$tbl.txt");
ok ($dbh->do ("create table $tbl (txt varchar (20))"), "Create table $tbl") or diag $dbh->errstr;
ok (-f $tbl_file, "Test table exists");

# Expected: ("unix", "perlio", "encoding(iso-8859-1)")
# use Data::Peek; DDumper [ @tfh ];
my @layer = grep { $_ eq "encoding($encoding)" } @tfhl;
is (scalar @layer, 1, "encoding shows in layer");

ok ($sth = $dbh->prepare ("select * from $tbl"), "Prepare select * from $tbl");
$rowidx = 0;
SKIP: {
    $using_dbd_gofer and skip "method intrusion didn't work with proxying", 1;
    ok ($sth->execute, "execute on $tbl");
    $dbh->errstr and diag;
    }

my $uctbl = uc($tbl);
ok ($sth = $dbh->prepare ("select * from $uctbl"), "Prepare select * from $uctbl");
$rowidx = 0;
SKIP: {
    $using_dbd_gofer and skip "method intrusion didn't work with proxying", 1;
    ok ($sth->execute, "execute on $uctbl");
    $dbh->errstr and diag;
    }

ok ($dbh->do ("drop table $tbl"), "table drop");
is (-s "$tbl.txt", undef, "Test table removed");

done_testing ();

sub DBD::File::Table::fetch_row ($$)
{
    my ($self, $data) = @_;
    my $meta = $self->{meta};
    if ($rowidx >= scalar @rows) {
	$self->{row} = undef;
	}
    else {
	$self->{row} = $rows[$rowidx++];
	}
    return $self->{row};
    } # fetch_row

sub DBD::File::Table::push_names ($$$)
{
    my ($self, $data, $row_aryref) = @_;
    my $meta = $self->{meta};
    @tfhl = PerlIO::get_layers ($meta->{fh});
    @{$meta->{col_names}} = @{$row_aryref};
    } # push_names
