-- Deploy table_company_feed
-- requires: schema_company
-- requires: table_company

BEGIN;

    SET client_min_messages = 'warning';
    SET search_path = 'company';

    CREATE TYPE company_feed_type AS ENUM(
        'company-created',       'company-updated',
        'admin-created',         'admin-deleted',
        'job-created',           'job-updated',
        'job-renewed',           'job-expired',
        'job-removed',           'job-promoted',
        'job-promotion-renewed', 'job-promotion-expired'
    );

    CREATE TABLE company_feed (
        id SERIAL PRIMARY KEY,
        company TEXT NOT NULL,
        happened_at TIMESTAMP NOT NULL DEFAULT NOW(),
        "type" company_feed_type NOT NULL,
        content TEXT
    );

COMMIT;