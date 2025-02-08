package Type::MoreUtils;

=pod

=encoding utf-8

=head1 name

Type::MoreUtils - Provide the stuff missing in Type::Tiny

=head1 SYNOPSIS

    # import specific functions
    use Type::MoreUtils qw( match_for );

    # import everything
    use Type::MoreUtils -all;

    # import all type constraint utilities like Never, Record, Pick and so on
    use Type::MoreUtils -types;

=head1 DESCRIPTION

B<Type::MoreUtils> provides some trivial but commonly needed functionality on lists which is not going to go into L<Type::Tiny>.

=head1 FUNCTIONS

=cut

use strict;
use warnings;
use feature 'state';

our $VERSION = "0.01";

use parent qw(Exporter::Tiny);

our @EXPORT_FUNCTIONS = qw(
    tkeys
    tvalues
    match_for
);

our @EXPORT_TYPES = qw(
    Never
    Record
    Partial
    Required
    Pick
    Omit
    Exclude
    Extract
);

our @EXPORT_OK = ( @EXPORT_FUNCTIONS, @EXPORT_TYPES );

our %EXPORT_TAGS = (
    all   => \@EXPORT_OK,
    types => \@EXPORT_TYPES,
);

use Carp qw(croak);
use Scalar::Util qw(refaddr);
use List::Util qw(uniq);
use List::MoreUtils::XS qw(duplicates);

use Types::Standard -types;
use Types::Equal qw(Eq);
use Type::Utils qw(union type);

=pod

=head2 tkeys $Type

C<tkeys> function returns the keys of a type.

Given a Dict type, it returns the keys of the type.

    my $T = Dict[foo => Int, bar => Str];
    tkeys $T
    # => ('foo', 'bar')

Given a union type, it returns the keys of all the types in the union.

    my $T = Dict[foo => Int, bar => Str] | Dict[baz => Int];
    tkeys $T
    # => ('foo', 'bar', 'baz')

Given an intersection type, it returns the keys of common keys in all the types in the intersection.

    my $T = Dict[foo => Int, bar => Int] & Dict[bar => Int];
    tkeys $T
    # => ('bar')

=cut

sub tkeys($) {
    my $T = Types::TypeTiny::to_TypeTiny( shift );

    if ($T->isa('Type::Tiny::Union')) {
        return uniq( map { &tkeys($_) } @{$T->type_constraints} );
    }
    elsif ($T->isa('Type::Tiny::Intersection')) {
        return duplicates( map { &tkeys($_) } @{$T->type_constraints} );
    }
    elsif ($T->is_strictly_subtype_of('Dict') && $T->has_parameters) {
        my @params = @{ $T->parameters };

        if (@params % 2 == 1) {
            pop @params; # remove slurpy
        }

        my @keys;
        for (my $i = 0; $i < @params; $i += 2) {
            push @keys => $params[$i];
        }
        return uniq(@keys);
    }
    elsif ($T->has_parent) {
        return &tkeys($T->parent);
    }
    else {
        # do nothing
    }
}

=pod

=head2 tvalues $Type

C<tvalues> function returns the values of a type.

Given a Enum type, it returns the values of the type.

    my $T = Enum[qw(foo bar)];
    my @values = tvalues($T);
    # => ('foo', 'bar')

Given a Dict type, it returns the values of the type.

    my $T = Dict[foo => Int, bar => Str];
    my @values = tvalues($T);
    # => (Int, Str)

=cut

sub tvalues($) {
    my $T = Types::TypeTiny::to_TypeTiny( shift );

    if ($T->isa('Type::Tiny::Union')) {
        return uniq( map { &tvalues($_) } @{$T->type_constraints} );
    }
    elsif ($T->isa('Type::Tiny::Intersection')) {
        return duplicates( map { &tvalues($_) } @{$T->type_constraints} );
    }
    elsif ($T->is_strictly_subtype_of('Dict') && $T->has_parameters) {
        my @params = @{ $T->parameters };

        if (@params % 2 == 1) {
            pop @params; # remove slurpy
        }

        my @values;
        for (my $i = 1; $i < @params; $i += 2) {
            push @values => $params[$i];
        }
        return uniq(@values);
    }
    elsif ($T->is_strictly_subtype_of('Tuple') && $T->has_parameters) {
        my @params = @{ $T->parameters };
        if ($params[-1] && $params[-1]->is_strictly_subtype_of('Slurpy')) {
            pop @params; # remove slurpy
        }
        return uniq(@params);
    }
    elsif ($T->can('values')) {
        return uniq(@{ $T->values });
    }
    elsif ($T->can('value')) {
        return ($T->value);
    }
    elsif ($T->has_parent) {
        return &tvalues($T->parent);
    }
    else {
        # do nothing
    }
}

=pod

=head2 match_for $Type, \%matches

C<match_for> function returns a coderef that matches the given type and returns the value corresponding to the key.

    my $Lang = Enum[qw(English Japanese)];

    my $hello = match_for($Lang, {
        English  => 'Hello',
        Japanese => 'こんにちは',
    });
    $hello->('English'); # => 'Hello'

It throws an error if the given C<\%matches> does not satisfy C<$Type>. It is useful for defining a mapping between types and values.

    my $bye = match_for($Lang, {
        English  => 'Goodbye',
    });
    # => Missing keys error: Japanese

    my $morning = match_for($Lang, {
        English  => 'Good morning',
        French   => 'Bonjour',
    });
    # => Unexpected keys error: French

=cut

sub match_for {
    my $Type = Types::TypeTiny::to_TypeTiny( shift );
    my $matches = shift;

    my @expected = tvalues $Type;
    my %expected_map = map { $_ => 1 } @expected;
    my @keys = keys %$matches;

    my @unexpected = grep { !exists $expected_map{$_} } @keys;
    my @missing = grep { !exists $matches->{$_} } @expected;

    if (@unexpected || @missing) {
        my @errors;
        push @errors, sprintf("unexpected keys: %s", join ',', @unexpected) if @unexpected;
        push @errors, sprintf("missing keys: %s", join ',', @missing) if @missing;

        croak sprintf('Invalid `match_for` %s: %s', $Type, join ', ', @errors);
    }

    return sub { $matches->{$_[0]} }
}


sub Never() {
    state $Never = type(name => 'Never', parent => Optional[sub { 0 }]);
}

sub Record {
    my $param = Types::TypeTiny::to_TypeTiny( shift );
    my ($T, $U) = @{$param};

    my @values = tvalues $T;
    my @ref_values = grep { ref $_ } @values;
    if (@ref_values) {
        die "must be string type";
    }

    Dict[ map { $_ => $U } @values ];
}

sub dict_map(&$) {
    my ($code, $T) = ($_[0], Types::TypeTiny::to_TypeTiny($_[1]));

    unless ($T->is_strictly_subtype_of('Dict')) {
        croak "must be Dict type";
    }

    if (!$T->has_parameters && $T->has_parent) {
        return &dict_map($T->parent, $code);
    }

    # Localise $a, $b
    my ($caller_a, $caller_b) = do
    {
        my $pkg = caller();
        no strict 'refs';
        \*{$pkg . '::a'}, \*{$pkg . '::b'};
    };

    my @pairs;
    for (my $i = 0; $i < @{$T->parameters}; $i += 2) {
        my $K = $T->parameters->[$i];
        my $V = $T->parameters->[$i + 1];

        local (*$caller_a, *$caller_b) = \($K, $V);
        my @pair = $code->($K, $V);

        unless (@pair == 2) {
            croak 'coderef must return pair';
        }

        push @pairs => @pair;
    }
    Dict[@pairs];
}

sub dict_grep(&$) {
    my ($code, $T) = ($_[0], Types::TypeTiny::to_TypeTiny($_[1]));

    unless ($T->is_strictly_subtype_of('Dict')) {
        croak "must be Dict type";
    }

    if (!$T->has_parameters && $T->has_parent) {
        return &dict_grep($T->parent, $code);
    }

    # Localise $a, $b
    my ($caller_a, $caller_b) = do
    {
        my $pkg = caller();
        no strict 'refs';
        \*{$pkg . '::a'}, \*{$pkg . '::b'};
    };

    my @pairs;
    for (my $i = 0; $i < @{$T->parameters}; $i += 2) {
        my $K = $T->parameters->[$i];
        my $V = $T->parameters->[$i + 1];

        local (*$caller_a, *$caller_b) = \($K, $V);
        if ($code->($K, $V)) {
            push @pairs => ($K => $V);
        }
    }
    Dict[@pairs];
}

sub Partial($) {
    my ($T) = _to_types(@_);

    dict_map { $a => $b->is_strictly_subtype_of('Optional') ? $b : Optional[$b] } $T;
}

sub Required($) {
    my ($T) = _to_types(@_);

    dict_map { $a => $b->is_strictly_subtype_of('Optional') ? $b->parameters->[0] : $b } $T;
}

sub Pick($$) {
    my ($T, $Keys) = _to_types(@_);

    my %keymap = map { $_ => 1 } tvalues $Keys;

    my $dict = dict_grep { delete $keymap{$a} } $T;

    if (my @missing = keys %keymap) {
        croak sprintf("missing keys: %s", join ', ', @missing);
    }

    $dict;
}

sub Omit($$) {
    my ($T, $Keys) = _to_types(@_);

    my %keymap = map { $_ => 1 } tvalues $Keys;
    dict_grep { not exists $keymap{$a} } $T;
}

sub union_grep(&$) {
    my ($code, $T) = ($_[0], Types::TypeTiny::to_TypeTiny($_[1]));

    unless ($T->isa('Type::Tiny::Union')) {
        croak "must be Union type";
    }

    my @items = map { ref $_ ? $_ : Eq[$_] } grep { $code->($_) } tvalues($T);
    @items ? union(\@items) : Never;
}

sub Exclude($$) {
    my ($T, $Keys) = _to_types(@_);

    my %keymap = map { $_ => 1 } tvalues $Keys;
    union_grep { not exists $keymap{$_} } $T;
}

sub Extract($$) {
    my ($T, $Keys) = _to_types(@_);

    my %keymap = map { $_ => 1 } tvalues $Keys;
    union_grep { exists $keymap{$_} } $T;
}

sub _to_types {
    map { Types::TypeTiny::to_TypeTiny($_) } (ref $_[0]||'') eq 'ARRAY' ? @{$_[0]} : @_;
}

1;
__END__
=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut

