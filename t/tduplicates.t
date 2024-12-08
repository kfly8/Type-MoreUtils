use Test2::V0;

use Type::MoreUtils qw(tduplicates);

is [ tduplicates() ], [];

is [ tduplicates(qw(a b c)) ], [];
is [ tduplicates(qw(a b c a)) ], [qw(a)];
is [ tduplicates(qw(a b c a a)) ], [qw(a)];

is [ tduplicates(undef, undef, 'a') ], [undef];
is [ tduplicates(undef, 'a', 'a') ], ['a'];

use Types::Standard -types;

my $Int = object { call name => 'Int' };
my $Str = object { call name => 'Str' };

is [ tduplicates(Int, Str) ], [];
is [ tduplicates(Int, Str, Int) ], [$Int];
is [ tduplicates(Int, Str, Int, Str) ], [$Int, $Str];
is [ tduplicates(Int, Int, Int) ], [$Int];

done_testing;
