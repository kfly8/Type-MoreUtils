use Test2::V0;

use Type::MoreUtils qw(tkeys);

use Types::Standard -types;

subtest 'Dict' => sub {
    my $expected = [qw(a b c)];
    my $T = Dict[ a => Int, b => Int, c => Int ];
    is [ tkeys $T ], $expected;

    my $T2 = Type::Tiny->new(parent => $T);
    is [ tkeys $T2 ], $expected;

    my $T3 = Dict[ a => Int, b => Int, c => Int, Slurpy[Str] ];
    is [ tkeys $T3 ], $expected;
};

subtest 'Map' => sub {
    my $Int = object { display_name => 'Int' };
    my $Str = object { display_name => 'Str' };
    my $expected = [$Int];

    my $T = Map[Int, Str];
    is [ tkeys $T ], $expected;

    my $T2 = Type::Tiny->new(parent => $T);
    is [ tkeys $T2 ], $expected;
};

subtest 'Union' => sub {
    my $expected = [qw(a b c)];

    my $T1 = Dict[ a => Int, b => Int ];
    my $T2 = Dict[ c => Int, Slurpy[Str] ];
    my $T = $T1 | $T2;

    is [ tkeys $T ], $expected;

    my $PT = Type::Tiny->new(parent => $T);
    is [ tkeys $PT ], $expected;
};

subtest 'Intersection' => sub {
    my $expected = [qw(b c)];

    my $T1 = Dict[ a => Int, b => Int, c => Int];
    my $T2 = Dict[ b => Int, c => Int, d => Int, Slurpy[Str] ];
    my $T = $T1 & $T2;

    is [ tkeys $T ], $expected;

    my $PT = Type::Tiny->new(parent => $T);
    is [ tkeys $PT ], $expected;
};

done_testing;
