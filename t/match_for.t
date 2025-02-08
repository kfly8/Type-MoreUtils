use Test2::V0;

use Type::MoreUtils qw(match_for);
use Types::Standard -types;

subtest 'Enum' => sub {
    my $Enum = Enum[qw(a b c)];

    ok lives {
        my $code = match_for $Enum, {
            a => 'apple',
            b => 'banana',
            c => 'cherry',
        };
        is $code->('a'), 'apple';
    };

    my $error = dies {
        my $code = match_for $Enum, {
            a => 'apple',
            d => 'doughnut',
        };
    };
    like $error, qr/missing keys: b,c/;
    like $error, qr/unexpected keys: d/;
};

done_testing;
