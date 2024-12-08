use Test2::V0;

use Type::MoreUtils qw(Record);
use Types::Standard -types;
use Types::Equal qw(Eq);

my $case = [
    {
        when => { English => 'Hello', Japanese => 'こんにちは' },
        then => !!1,
    },
    {
        when => { English => 'Hello' },
        then => !!0,
    },
    {
        when => { Japanese => 'こんにちは' },
        then => !!0,
    },
];

subtest 'Record with Enum' => sub {
    my $Lang = Enum[qw(English Japanese)];
    my $Hello = Record[$Lang, Str];

    for my $c (@$case) {
        is $Hello->check($c->{when}), $c->{then};
    }
};

subtest 'Record with Eq union' => sub {
    my $Lang = Eq['English'] | Eq['Japanese'];
    my $Hello = Record[$Lang, Str];

    for my $c (@$case) {
        is $Hello->check($c->{when}), $c->{then};
    }
};

done_testing;
