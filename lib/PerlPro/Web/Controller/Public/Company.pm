package PerlPro::Web::Controller::Public::Company;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller' }

sub base :Chained('/') PathPart('') CaptureArgs(0) {
    my ( $self, $ctx ) = @_;
    $ctx->stash(
        current_model_instance => $ctx->model('DB::Company')
    );
}

sub profile :Chained('base') PathPart('company') Args(1) GET {
    my ( $self, $ctx, $id ) = @_;

    $ctx->stash(
        c => $ctx->model->get_for_profile($id)
    );
}

sub catalog :Chained('base') PathPart('companies') Args(0) GET {
    my ( $self, $ctx ) = @_;

    my $search = $ctx->model->get_for_catalog(int($ctx->req->params->{p} || 1));

    $ctx->stash(
        companies => $search->{companies},
        pager     => $search->{pager},
    );
}

# This is for the typeahead at the /search page
sub companies_like :Chained('base') PathPart('companies') Args(1) GET {
    my ( $self, $ctx, $query ) = @_;

    my $companies = $ctx->model->get_for_typeahead($query);

    $ctx->stash(
        current_view => 'JSON',
        json_data    => {
            companies => $companies
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

PerlPro::Web::Controller::Public::Company - Catalyst Controller

=head1 DESCRIPTION

Controller for browsing companies.

=head1 METHODS

=head2 base

Top of the chain of all methods in this class.

=head2 profile

Display the profile of a given company.

=head2 catalog

Display a list of all companies registered.

=head1 AUTHOR

André Walker

=head1 LICENSE

This file is part of PerlPro.

PerlPro is free software: you can redistribute it and/or modify it under the
terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.
