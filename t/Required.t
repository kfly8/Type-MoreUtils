use Test2::V0;

use Type::MoreUtils qw(Required);
use Types::Standard -types;

my $T = Dict[foo => Int, bar => Optional[Int]];

my $R = Required($T);

ok !$R->check({foo => 1});
ok !$R->check({bar => 1});
ok $R->check({foo => 1, bar => 1});
ok !$R->check({});

done_testing;
