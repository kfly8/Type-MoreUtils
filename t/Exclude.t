use Test2::V0;

use Type::MoreUtils qw(Exclude);
use Types::Standard -types;
use Types::Equal qw(Eq);

my $T = Eq["foo"] | Eq["bar"] | Eq["baz"];

my $Keys = Enum[qw/foo bar/];

my $P = Exclude($T, $Keys);

ok !$P->check("foo");
ok !$P->check("bar");
ok $P->check("baz");

note $P;

done_testing;
