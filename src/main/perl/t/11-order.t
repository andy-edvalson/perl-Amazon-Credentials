use strict;
use warnings;

use Test::More tests => 5;

use Data::Dumper;
use English qw{ -no_match_vars };
use UnitTestSetup;

BEGIN {
  use_ok('Amazon::Credentials');
}

init_test;

my $creds = Amazon::Credentials->new(
  { order => [qw/file/],
    debug => $ENV{DEBUG} ? 1 : 0,
  }
);

ok( ref $creds, 'found credentials in file' );

is( $creds->get_aws_access_key_id,
  'bar-aws-access-key-id', 'default profile' );

$creds = eval { return Amazon::Credentials->new( order => 'blah' ); };

like( $EVAL_ERROR, qr/invalid/, 'only valid locations' );

$creds
  = eval { return Amazon::Credentials->new( order => { this => 'blah' } ); };

like( $EVAL_ERROR, qr/array ref/, 'only array refs or scalars' );

