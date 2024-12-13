use Test2::V0;

use Type::MoreUtils qw(DefinedUnion);
use Types::Standard -types;
use Types::Equal qw(Equ);

my $T = Equ["foo"] | Equ["bar"] | Equ[undef];

my $P = DefinedUnion($T);

ok $P->check("foo");
ok $P->check("bar");
ok !$P->check(undef);

note $P;

done_testing;
