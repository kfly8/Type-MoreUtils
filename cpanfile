requires 'perl', '5.016000';

requires 'Type::Tiny';
requires 'Types::Equal', '0.02';

on 'test' => sub {
    requires 'Test2::V0' => '0.000147';
};

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};
