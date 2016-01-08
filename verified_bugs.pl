#!/usr/bin/perl
## Description : Show verified bugs in a date range
## Author : Kuriens Maliekal

# Variables to adjust

my $url = "http://BUGZILLA_URL/report_users.cgi";

# No changes required below this line

use LWP::UserAgent;
use HTTP::Cookies;
use Getopt::Std;
use Text::Table;

my $tflag = 0;
my %opts = ();
getopts("u:d:", \%opts);

die "-d option not specified" unless defined $opts{d};
die "-d argument not a number" if $opts{d} =~ /\D/;

my @tmp = localtime();
my $todate = ($tmp[5]+1900) . "-" . ($tmp[4]+1) . "-" . $tmp[3];
@tmp = localtime(time() - ($opts{d}*86400));
my $fromdate = ($tmp[5]+1900) . "-" . ($tmp[4]+1) . "-" . $tmp[3];

my $ua = LWP::UserAgent->new;
push(@{$ua->requests_redirectable}, 'POST');

print "Enter bugzilla username : ";
my $bug_user = <STDIN>;
print "Enter bugzilla password : ";
system("stty","-echo");
my $bug_pass = <STDIN>;
system("stty","echo");

$ua->cookie_jar({ file => "/tmp/.cookies.txt" });
$response = $ua->post($url, 
	['Bugzilla_login' => "$bug_user",
	'Bugzilla_password' => "$bug_pass",
	'Bugzilla_restrictlogin' => 'on',
	'action' => 'verifiedbugs',
	'fromdt' => "$fromdate",
	'todt' => "$todate",
	'teamid' => '110',
	'search' => 'Show Verified Bugs',
	'GoAheadAndLogIn' => 'Log in']);
my $tmp1 = $response->content;
my @contents = split(/<tr>/, $tmp1); #split the entire page contents into @arr1
shift @contents; #remove the header
printf "\n";
my $table = Text::Table->new(\'| ',"BugID",\'| ',"Tech_ID",\'| ',"QA_ID",\'| ',"Resolution",\'| ');
my $rule = $table->rule(qw/- +/);
foreach my $rows (@contents) {
	(@data) = ($rows =~ />([^><]+)</g); #get text within HTML tags into @match
	if(defined $opts{u}) {
		if($data[1] =~ /\Q$opts{u}\E/) {
			$table->load([$data[0], $data[1], $data[3], $data[5]]);
		}
	}
	else {
		$table->load([$data[0], $data[1], $data[3], $data[5]]);
	}
}
my @table_body = $table->body();
print $rule, $table->title, $rule;
foreach (@table_body) {
	print $_ . $rule;
}
