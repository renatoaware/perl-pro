use utf8;
package PerlPro::Schema::Result::CompanyEmail;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PerlPro::Schema::Result::CompanyEmail

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::EncodedColumn>

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("EncodedColumn", "InflateColumn::DateTime");

=head1 TABLE: C<company_email>

=cut

__PACKAGE__->table("company_email");

=head1 ACCESSORS

=head2 company

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 email

  data_type: 'text'
  is_nullable: 0

=head2 is_main_address

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "company",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "email",
  { data_type => "text", is_nullable => 0 },
  "is_main_address",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</company>

=item * L</email>

=back

=cut

__PACKAGE__->set_primary_key("company", "email");

=head1 RELATIONS

=head2 company

Type: belongs_to

Related object: L<PerlPro::Schema::Result::Company>

=cut

__PACKAGE__->belongs_to(
  "company",
  "PerlPro::Schema::Result::Company",
  { name_in_url => "company" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-08-15 14:19:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FBTP+B1m+l3cdBHnd3DZxg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
