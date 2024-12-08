use Test2::V0;

use Type::MoreUtils qw(Never);
use Types::Standard -types;

subtest 'Never type does not accept any value' => sub {
    ok !Never->check(1);
    ok !Never->check('foo');
    ok !Never->check(undef);
};

subtest 'Never with Dict' => sub {
    my $type = Dict[
        foo => Never,
        bar => Str,
    ];

    ok !$type->check({ foo => 'foo', bar => 'baz' });
    ok !$type->check({ foo => 1, bar => 'baz' });
    ok !$type->check({ foo => undef, bar => 'baz' });
    ok $type->check({ bar => 'baz' });
};

subtest 'Never with Tuple' => sub {
    my $type = Tuple[Str, Never];

    ok !$type->check(['foo', 'bar']);
    ok !$type->check(['foo', 1]);
    ok !$type->check(['foo', undef]);
    ok $type->check(['foo']);
};

done_testing;
