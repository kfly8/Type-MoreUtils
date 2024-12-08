use Test2::V0;

use Type::MoreUtils qw(tuniq);

is [ tuniq() ], [];

is [ tuniq(qw(a b c)) ], [qw(a b c)];
is [ tuniq(qw(a b c a)) ], [qw(a b c)];
is [ tuniq(qw(a b c a a)) ], [qw(a b c)];

is [ tuniq(undef, undef, 'a') ], [undef, 'a'];
is [ tuniq(undef, 'a', 'a') ], [undef, 'a'];

use Types::Standard -types;

my $Int = object { call name => 'Int' };
my $Str = object { call name => 'Str' };

is [ tuniq(Int, Str) ], [$Int, $Str];
is [ tuniq(Int, Int, Int) ], [$Int];
is [ tuniq(Int, Str, Int) ], [$Int, $Str];

done_testing;
