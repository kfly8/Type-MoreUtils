use Test2::V0;

use Type::MoreUtils qw(Pick);
use Types::Standard -types;

my $T = Dict[foo => Int, bar => Str, baz => Any];

my $Keys = Enum[qw/foo bar/];

my $P = Pick($T, $Keys);

ok $P->check({foo => 1, bar => 'a'});
ok !$P->check({foo => 1, bar => 'a', baz => 1});
ok !$P->check({foo => 1 });

note $P;

done_testing;
