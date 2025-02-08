package Type::MoreUtils;
use strict;
use warnings;
use feature 'state';

our $VERSION = "0.01";

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(key_of value_of match_for tuniq tduplicates Never Record Partial Required Pick Omit Exclude Extract DefinedUnion);

use Carp qw(croak);
use Scalar::Util qw(refaddr);

use Types::Standard -types;
use Types::Equal qw(Eq);
use Type::Utils qw(union type);

sub key_of($) {
    my $T = Types::TypeTiny::to_TypeTiny( shift );

    my $keys = [];

    if ($T->isa('Type::Tiny::Union')) {
        my @keys = map { &key_of($_) } @{$T->type_constraints};
        $keys = [ tuniq(@keys) ];
    }
    elsif ($T->isa('Type::Tiny::Intersection')) {
        my @keys = map { &key_of($_) } @{$T->type_constraints};
        $keys = [ tduplicates(@keys) ];
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
        $keys = [ tuniq(@keys) ];
    }
    elsif ($T->has_parent) {
        $keys = [ &key_of($T->parent) ];
    }
    else {
        # do nothing
    }

    wantarray ? @{$keys} : $keys;
}

sub value_of($) {
    my $T = Types::TypeTiny::to_TypeTiny( shift );

    my $values = [];

    if ($T->isa('Type::Tiny::Union')) {
        my @values = map { &value_of($_) } @{$T->type_constraints};
        $values = [ tuniq(@values) ];
    }
    elsif ($T->isa('Type::Tiny::Intersection')) {
        my @values = map { &value_of($_) } @{$T->type_constraints};
        $values = [ tduplicates(@values) ];
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
        $values = [ tuniq(@values) ];
    }
    elsif ($T->is_strictly_subtype_of('Tuple') && $T->has_parameters) {
        $values = [ @{ $T->parameters } ];
    }
    elsif ($T->can('values')) {
        $values = [ tuniq(@{ $T->values }) ];
    }
    elsif ($T->can('value')) {
        $values = [ $T->value ];
    }
    elsif ($T->has_parent) {
        $values = [ &value_of($T->parent) ];
    }
    else {
        # do nothing
    }

    wantarray ? @{$values} : $values;
}

sub match_for {
    my $Type = Types::TypeTiny::to_TypeTiny( shift );
    my $matches = shift;

    my @expected = value_of $Type;
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

sub tuniq(@) {
    my %seen;
    my %seen_ref;
    my $seen_undef;
    my $k;
    grep {
          ref $_     ? not $seen_ref{$k = refaddr $_}++
        : defined $_ ? not $seen{$k = $_}++
        :              not $seen_undef++
    } @_;
}

sub tduplicates(@) {
    my %seen;
    my %seen_ref;
    my $seen_undef;
    my $k;

    grep { 1 < ( ref $_ ? $seen_ref{$k = refaddr $_} : defined $_ ? $seen{$k = $_} : $seen_undef) }
    grep {
            ref $_     ? not $seen_ref{$k = refaddr $_}++
          : defined $_ ? not $seen{$k = $_}++
          : not $seen_undef++
    } @_;
}

sub Never() {
    state $Never = type(name => 'Never', parent => Optional[sub { 0 }]);
}

sub Record {
    my $param = Types::TypeTiny::to_TypeTiny( shift );
    my ($T, $U) = @{$param};

    my @values = value_of $T;
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

    my %keymap = map { $_ => 1 } value_of $Keys;

    my $dict = dict_grep { delete $keymap{$a} } $T;

    if (my @missing = keys %keymap) {
        croak sprintf("missing keys: %s", join ', ', @missing);
    }

    $dict;
}

sub Omit($$) {
    my ($T, $Keys) = _to_types(@_);

    my %keymap = map { $_ => 1 } value_of $Keys;
    dict_grep { not exists $keymap{$a} } $T;
}

sub union_grep(&$) {
    my ($code, $T) = ($_[0], Types::TypeTiny::to_TypeTiny($_[1]));

    unless ($T->isa('Type::Tiny::Union')) {
        croak "must be Union type";
    }

    my @items = map { ref $_ ? $_ : Eq[$_] } grep { $code->($_) } value_of($T);
    @items ? union(\@items) : Never;
}

sub Exclude($$) {
    my ($T, $Keys) = _to_types(@_);

    my %keymap = map { $_ => 1 } value_of $Keys;
    union_grep { not exists $keymap{$_} } $T;
}

sub Extract($$) {
    my ($T, $Keys) = _to_types(@_);

    my %keymap = map { $_ => 1 } value_of $Keys;
    union_grep { exists $keymap{$_} } $T;
}

sub DefinedUnion($) {
    my ($T) = _to_types(@_);
    union_grep { defined $_ } $T;
}

sub _to_types {
    map { Types::TypeTiny::to_TypeTiny($_) } (ref $_[0]||'') eq 'ARRAY' ? @{$_[0]} : @_;
}

1;
__END__

=encoding utf-8

=head1 NAME

Type::MoreUtils - It's new $module

=head1 SYNOPSIS

    use Type::MoreUtils;

=head1 DESCRIPTION

Type::MoreUtils is ...

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut

