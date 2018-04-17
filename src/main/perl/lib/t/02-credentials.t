use strict;
use warnings;

use Test::More tests => 6;

use Data::Dumper;
use Date::Format;
use File::Path;
use JSON;

use File::Temp qw/:mktemp/;

BEGIN {
  {
    no strict 'refs';
    
    *{'HTTP::Request::new'} = sub { bless{}, 'HTTP::Request'; };
    *{'HTTP::Request::request'} = sub { new HTTP::Response; };

    *{'HTTP::Response::new'} = sub { bless{}, 'HTTP::Response'; };
    *{'HTTP::Response::is_success'} = sub { 1; };

    *{'LWP::UserAgent::new'} = sub { bless {}, 'LWP::UserAgent'; };
    *{'LWP::UserAgent::request'} = sub { new HTTP::Response; };
  }

  use Module::Loaded;

  mark_as_loaded(HTTP::Request);
  mark_as_loaded(HTTP::Response);
  mark_as_loaded(LWP::UserAgent);

  use_ok('Amazon::Credentials');
}

my $home = mkdtemp("amz-credentials-XXXXX");

my $credentials_file = eval {
  mkdir "$home/.aws";
  
  open (my $fh, ">$home/.aws/credentials") or BAIL_OUT("could not create temporary credentials file");
  print $fh <<eot;
[foo]
aws_access_key_id=foo-aws-access-key-id
aws_secret_access_key=foo-aws-secret-access-key

[bar]
aws_access_key_id=bar-aws-access-key-id
aws_secret_access_key=bar-aws-secret-access-key
eot
  close $fh;
  "$home/.aws/credentials";
};

$ENV{HOME} = "$home";
my $creds = new Amazon::Credentials({ order => [qw/file/], debug => 0 });
ok(ref($creds), 'find credentials');

my %new_creds = (
		 aws_access_key_id     => 'biz-aws-access-key-id',
		 aws_secret_access_key => 'biz-aws-secret-access-key',
		 token                 => 'biz',
		 expiration            => time2str("%Y-%m-%dT%H:%M:%S%Z", time + -5 + (5 * 60), "Z")
		);

$creds->set_credentials(\%new_creds);
ok($creds->is_token_expired, 'is_token_expired() - yes?');

$creds->set_expiration(time2str("%Y-%m-%dT%H:%M:%S%Z", time + 5 + (5 * 60),"Z"));
ok(! $creds->is_token_expired, 'is_token_expired() - no?');

# expire token
$creds->set_expiration(time2str("%Y-%m-%dT%H:%M:%S%Z", time + -5 + (5 * 60),"Z"));
ok($creds->is_token_expired, 'is_token_expired() - reset as expired');

$new_creds{AccessKeyId} = 'buz-aws-access-key-id';
$new_creds{Expiration} = time2str("%Y-%m-%dT%H:%M:%S%Z", time + 5 + (5 * 60),"Z");
$new_creds{SecretAccessKey} = 'buz-aws-secret-access-key';
$new_creds{Token} = 'buz';

my $content = to_json(\%new_creds);

{
  no strict 'refs';
  my $response = ['role', $content];
  *{'HTTP::Response::content'} = sub { shift @{$response}; };
}

$creds->set_role('role');
$creds->refresh_token;

ok(! $creds->is_token_expired, 'refresh_token()');

END {
  eval {
    rmtree($home)
      if $home;
  };
}
