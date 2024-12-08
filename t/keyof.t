use Test2::V0;

use Type::MoreUtils qw(keyof);

use Types::Standard -types;

subtest 'Dict' => sub {
    my $expected = [qw(a b c)];
    my $T = Dict[ a => Int, b => Int, c => Int ];
    is [ keyof $T ], $expected;

    my $T2 = Type::Tiny->new(parent => $T);
    is [ keyof $T2 ], $expected;

    my $T3 = Dict[ a => Int, b => Int, c => Int, Slurpy[Str] ];
    is [ keyof $T3 ], $expected;
};

subtest 'Union' => sub {
    my $expected = [qw(a b c)];

    my $T1 = Dict[ a => Int, b => Int ];
    my $T2 = Dict[ c => Int, Slurpy[Str] ];
    my $T = $T1 | $T2;

    is [ keyof $T ], $expected;

    my $PT = Type::Tiny->new(parent => $T);
    is [ keyof $PT ], $expected;
};

subtest 'Intersection' => sub {
    my $expected = [qw(b c)];

    my $T1 = Dict[ a => Int, b => Int, c => Int];
    my $T2 = Dict[ b => Int, c => Int, d => Int, Slurpy[Str] ];
    my $T = $T1 & $T2;

    is [ keyof $T ], $expected;

    my $PT = Type::Tiny->new(parent => $T);
    is [ keyof $PT ], $expected;
};

done_testing;
