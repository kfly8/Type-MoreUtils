use Test2::V0;

use Type::MoreUtils qw(valueof);

use Types::Standard -types;

subtest 'Enum' => sub {
    my $expected = [qw(a b c)];
    my $T = Enum[qw(a b c)];

    is [ valueof $T ], $expected;

    my $PT = Type::Tiny->new(parent => $T);
    is [ valueof $PT ], $expected;
};

subtest 'Dict' => sub {
    my $Int = object { display_name => 'Int' };
    my $Str = object { display_name => 'Str' };
    my $Any = object { display_name => 'Any' };

    my $T = Dict[ a => Int, b => Str, c => Any];

    is [ valueof $T ], [$Int, $Str, $Any];

    my $T2 = Type::Tiny->new(parent => $T);
    is [ valueof $T2 ], [$Int, $Str, $Any];

    my $T3 = Dict[ a => Int, b => Int, c => Int, Slurpy[Str] ];
    is [ valueof $T3 ], [$Int];
};

done_testing;
