-- Deploy table_company_email
-- requires: schema_company
-- requires: table_company

BEGIN;

    SET client_min_messages = 'warning';
    SET search_path = 'company';

    CREATE TABLE company_email (
        company TEXT NOT NULL,
        email TEXT NOT NULL,
        PRIMARY KEY(company, email),
        FOREIGN KEY (company) REFERENCES company(name_in_url) ON DELETE CASCADE ON UPDATE CASCADE
    );

COMMIT;