use Test2::V0;

use Type::MoreUtils qw(Partial);
use Types::Standard -types;

my $T = Dict[foo => Int, bar => Optional[Int]];

my $P = Partial($T);

ok $P->check({foo => 1});
ok $P->check({bar => 1});
ok $P->check({foo => 1, bar => 1});
ok $P->check({});

done_testing;
