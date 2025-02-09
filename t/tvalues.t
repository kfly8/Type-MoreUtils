use Test2::V0;

use Type::MoreUtils qw(tvalues);

use Types::Standard -types;

subtest 'Enum' => sub {
    my $expected = [qw(a b c)];
    my $T = Enum[qw(a b c)];

    is [ tvalues $T ], $expected;

    my $PT = Type::Tiny->new(parent => $T);
    is [ tvalues $PT ], $expected;
};

subtest 'Dict' => sub {
    my $Int = object { display_name => 'Int' };
    my $Str = object { display_name => 'Str' };
    my $Any = object { display_name => 'Any' };

    my $T = Dict[ a => Int, b => Str, c => Any ];

    is [ tvalues $T ], [$Int, $Str, $Any];

    my $T2 = Type::Tiny->new(parent => $T);
    is [ tvalues $T2 ], [$Int, $Str, $Any];

    my $T3 = Dict[ a => Int, b => Int, c => Int, Slurpy[Str] ];
    is [ tvalues $T3 ], [$Int], 'Exclude Slurpy';
};

subtest 'Map' => sub {
    my $Int = object { display_name => 'Int' };
    my $Str = object { display_name => 'Str' };

    my $T = Map[Int, Str];
    is [ tvalues $T ], [$Str];

    my $T2 = Type::Tiny->new(parent => $T);
    is [ tvalues $T2 ], [$Str];
};

subtest 'Tuple' => sub {
    my $Int = object { display_name => 'Int' };
    my $Str = object { display_name => 'Str' };

    my $T = Tuple[Int, Str, Str];
    is [ tvalues $T ], [$Int, $Str];

    my $T2 = Type::Tiny->new(parent => $T);
    is [ tvalues $T2 ], [$Int, $Str];

    my $T3 = Tuple[Int, Slurpy[Str]];
    is [ tvalues $T3 ], [$Int], 'Exclude Slurpy';
};

done_testing;
