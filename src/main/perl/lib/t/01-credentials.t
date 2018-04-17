use strict;
use warnings;

use Test::More tests => 4;

use File::Temp qw/:mktemp/;
use File::Path;

BEGIN {
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
my $creds = new Amazon::Credentials({ order => [qw/file/] });
ok(ref($creds), 'find credentials');
is($creds->get_aws_access_key_id, 'foo-aws-access-key-id', 'default profile');

$creds = new Amazon::Credentials({ profile => 'bar', order => [qw/file/] });
is($creds->{aws_access_key_id}, 'bar-aws-access-key-id', 'retrieve profile');

END {
  eval {
    rmtree($home)
      if $home;
  };
}
