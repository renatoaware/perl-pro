package PerlPro::Schema::ResultSet::Company;

use Moose;
use namespace::autoclean;

extends 'DBIx::Class::ResultSet';
with 'PerlPro::Role::Verification';

use MooseX::Types::Email qw/EmailAddress/;
use MooseX::Types::Moose qw/Str Bool/;
use MooseX::Types::URI qw/Uri/;
use HTML::Entities ();
use Text::Unaccent::PurePerl ();

use Data::Verifier;

sub _build_verifier_scope_name { 'company' }

sub verifiers_specs {
    my $self = shift;

    return {
        register => Data::Verifier->new(
            profile => {
                name        => { required => 1, type => Str          },
                description => { required => 1, type => Str          },
                email       => { required => 1, type => EmailAddress },
                phone       => { required => 1, type => Str          },
                address     => { required => 1, type => Str          },
                city        => { required => 1, type => Str          },
                state       => { required => 1, type => Str          },
            },
            filters => [
                sub { HTML::Entities::encode_entities( $_[0] ) }
            ],
        ),
        add_email => Data::Verifier->new(
            profile => {
                company => { required => 1, type => Str          },
                email   => { required => 1, type => EmailAddress },
                is_main => { required => 0, type => Bool         },
            },
        ),
        add_phone => Data::Verifier->new(
            profile => {
                company => { required => 1, type => Str  },
                phone   => { required => 1, type => Str  },
                is_main => { required => 0, type => Bool },
            },
        ),
        add_website => Data::Verifier->new(
            profile => {
                company => { required => 1, type => Str  },
                url     => { required => 1, type => Uri  },
                is_main => { required => 0, type => Bool },
            },
        ),
        add_location => Data::Verifier->new(
            profile => {
                company  => { required => 1, type => Str  },
                location => { required => 1, type => Str  }, # FIXME
                is_main  => { required => 0, type => Bool },
            },
        ),
    };
}

sub action_specs {
    my $self = shift;
    return {
        register => sub {
            my %values = shift->valid_values;

            my $name_in_url = lc Text::Unaccent::PurePerl::unac_string($values{name});
            $name_in_url =~ s/\s+/_/g;
            $name_in_url =~ s/[^a-z0-9_]//g;

            my $row = $self->create({
                name_in_url => $name_in_url,
                name        => $values{name},
                description => $values{description},
            });

            $row->add_to_company_emails({ email => $values{email}, is_main_address => 1 });
            $row->add_to_company_phones({ phone => $values{phone}, is_main_phone   => 1 });

            $row->add_to_company_locations({
                address         => $values{address},
                city            => $values{city},
                state           => $values{state},
                country         => 'Brazil', # later on, it won't be hardcoded
                is_main_address => 1,
            });

            return $row;
        },
        add_email => sub {
            my %values = shift->valid_values;
            my $row = $self->find($values{company});
            $row->add_to_emails({
                email => $values{email},
                is_main_address => $values{is_main},
            });
            return $row;
        },
        add_phone => sub {
            my %values = shift->valid_values;
            my $row = $self->find($values{company});
            $row->add_to_phones({
                phone => $values{phone},
                is_main_phone => $values{is_main},
            });
            return $row;
        },
        add_website => sub {
            my %values = shift->valid_values;
            my $row = $self->find($values{company});
            $row->add_to_websites({
                url => $values{url},
                is_main_website => $values{is_main},
            });
            return $row;
        },
        add_location => sub {
            my %values = shift->valid_values;
            my $row = $self->find($values{company});
            $row->add_to_locations({
                location => $values{location},          # FIXME
                is_main_address => $values{is_main},
            });
            return $row;
        },
    };
}

sub get_for_profile {
    my ($self, $id) = @_;

    my $company = $self->find($id);

    return unless $company;

    my $website_obj = $company->company_websites->search({}, {
        order_by => { -desc => 'is_main_website' }
    })->first;
    my $phone_obj = $company->company_phones->search({}, {
        order_by => { -desc => 'is_main_phone' }
    })->first;
    my $email_obj = $company->company_emails->search({}, {
        order_by => { -desc => 'is_main_address' }
    })->first;
    my $location_obj = $company->company_locations->search({}, {
        order_by => { -desc => 'is_main_address' }
    })->first;

    my $url   = $website_obj ? $website_obj->url : '';
    my $email = $email_obj   ? $email_obj->email : '';
    my $phone = $phone_obj   ? $phone_obj->phone : '';

    my $formatted_address = $location_obj
                          ? ( $location_obj->address . ", "
                            . $location_obj->city    . " - "
                            . $location_obj->state )
                          : ''
                          ;

    my $search = $company->jobs->search({
        'me.status' => 'active',
    }, {
        join     => [qw/promoted job_location/],
        order_by => { -desc => [ 'promoted.status', 'created_at' ] }, # promoted first
        rows     => 8,
        select   => [ qw/promoted.status me.title job_location.city/ ],
        as       => [ qw/promotion title city/ ],
    });

    my @jobs = map {
        +{
            title     => $_->get_column('title'),
            promotion => $_->get_column('promotion'),
            city      => $_->get_column('city'),
        }
    } $search->all;

    my $jc     = scalar @jobs;
    my $middle = int($jc/2);
    my $part_one = \@jobs;
    my $part_two = [];

    if ($middle > 0) {
        $part_one = [ @jobs[0..$middle] ];
        $part_two = [ @jobs[($middle+1)..$jc] ];
    }

    return {
        name_in_url       => $company->name_in_url,
        name              => $company->name,
        description       => $company->description,
        website           => $url,
        email             => $email,
        phone             => $phone,
        formatted_address => $formatted_address,
        jobs_part_1       => $part_one,
        jobs_part_2       => $part_two,
    }
}

sub get_to_edit {
    my ($self, $id) = @_;

    my $company = $self->find($id);

    return unless $company;

    my @websites = $company->company_websites->search({}, {
        order_by => { -desc => 'is_main_website' }
    })->all;
    my @phones   = $company->company_phones->search({}, {
        order_by => { -desc => 'is_main_phone' }
    })->all;
    my @emails   = $company->company_emails->search({}, {
        order_by => { -desc => 'is_main_address' }
    })->all;
    my @locations = $company->company_locations->search({}, {
        order_by => { -desc => 'is_main_address' }
    })->all;

    my $email = scalar @emails ? $emails[0]->email : '';

    return {
        name_in_url    => $company->name_in_url,
        name           => $company->name,
        description    => $company->description,
        websites       => \@websites,
        emails         => \@emails,
        phones         => \@phones,
        locations      => \@locations,
        email          => $email,
        open_positions => $company->jobs->search({ status => 'active' })->count,
    }
}

sub get_featured_companies {
    my $self = shift;
    my @result;

    my $rs = $self->search( {}, {
        distinct  => 1,
        rows      => 3,
        order_by  => { -desc => [ 'active_jobs', 'me.mtime' ] },
        '+select' => [
            {
                count => 'jobs.id',
                -as   => 'active_jobs'
            }
        ],
        '+as'    => ['open_positions'],
        '+where' => { 'jobs.status' => 'active' },
        columns  => [qw/name_in_url name/],
        join     => 'jobs',
    } );

    for ( $rs->all ) {
        push @result, {
            name_in_url    => $_->name_in_url,
            name           => $_->name,
            open_positions => $_->get_column('open_positions'),
        };
    }

    return \@result;
}

sub get_for_catalog {
    my ($self, $page) = @_;

    # TODO: real paging
    my $search = $self->search({}, { rows => 50, page => $page });
    my @result;

    for my $c ($search->all) {
        my $website_obj = $c->company_websites->search({}, {
            order_by => { -desc => 'is_main_website' }
        })->first;
        my $location_obj = $c->company_locations->search({}, {
            order_by => { -desc => 'is_main_address' }
        })->first;

        push @result, {
            name           => $c->name,
            name_in_url    => $c->name_in_url,
            open_positions => $c->jobs->search({ status => 'active' })->count,
            website        => $website_obj  ? $website_obj->url   : '',
            city           => $location_obj ? $location_obj->city : '',
        };
    }

    return {
        companies => \@result,
        pager => $search->pager,
    };
}

sub get_for_typeahead {
    my ($self, $query) = @_;
    my %result;

    my $rs = $self->search(
        {
            name => { -ilike => "%$query%" }
        },
        {
            columns => [ qw/name_in_url name/ ],
            rows => 10,
        }
    );

    for ($rs->all) {
        $result{ $_->name_in_url } = $_->name;
    }

    return \%result;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
