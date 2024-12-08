package Type::MoreUtils;
use strict;
use warnings;

our $VERSION = "0.01";

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(keyof valueof tuniq tduplicates Never Record);

use Scalar::Util qw(refaddr);

use Types::Standard -types;
use Types::Equal qw(Eq);

sub keyof($) {
    my $T = Types::TypeTiny::to_TypeTiny( shift );

    my $keys = [];

    if ($T->isa('Type::Tiny::Union')) {
        my @keys = map { &keyof($_) } @{$T->type_constraints};
        $keys = [ tuniq(@keys) ];
    }
    elsif ($T->isa('Type::Tiny::Intersection')) {
        my @keys = map { &keyof($_) } @{$T->type_constraints};
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
        $keys = [ &keyof($T->parent) ];
    }
    else {
        # do nothing
    }

    wantarray ? @{$keys} : $keys;
}

sub valueof($) {
    my $T = Types::TypeTiny::to_TypeTiny( shift );

    my $values = [];

    if ($T->isa('Type::Tiny::Union')) {
        my @values = map { &valueof($_) } @{$T->type_constraints};
        $values = [ tuniq(@values) ];
    }
    elsif ($T->isa('Type::Tiny::Intersection')) {
        my @values = map { &valueof($_) } @{$T->type_constraints};
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
        $values = [ &valueof($T->parent) ];
    }
    else {
        # do nothing
    }

    wantarray ? @{$values} : $values;
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

# Index access
sub IndexOf($$) {
    ...
}

{
    my $Never = Optional[sub { 0 }];
    sub Never() { $Never }
}

sub Record {
    my $param = Types::TypeTiny::to_TypeTiny( shift );
    my ($T, $U) = @{$param};

    my @values = valueof $T;
    my @ref_values = grep { ref $_ } @values;
    if (@ref_values) {
        die "must be string type";
    }

    Dict[ map { $_ => $U } @values ];
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

