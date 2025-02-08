use Test2::V0;

use Type::MoreUtils qw(value_of);

use Types::Standard -types;

subtest 'Enum' => sub {
    my $expected = [qw(a b c)];
    my $T = Enum[qw(a b c)];

    is [ value_of $T ], $expected;

    my $PT = Type::Tiny->new(parent => $T);
    is [ value_of $PT ], $expected;
};

subtest 'Dict' => sub {
    my $Int = object { display_name => 'Int' };
    my $Str = object { display_name => 'Str' };
    my $Any = object { display_name => 'Any' };

    my $T = Dict[ a => Int, b => Str, c => Any ];

    is [ value_of $T ], [$Int, $Str, $Any];

    my $T2 = Type::Tiny->new(parent => $T);
    is [ value_of $T2 ], [$Int, $Str, $Any];

    my $T3 = Dict[ a => Int, b => Int, c => Int, Slurpy[Str] ];
    is [ value_of $T3 ], [$Int];
};

done_testing;
