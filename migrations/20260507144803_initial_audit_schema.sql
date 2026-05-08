CREATE DATABASE stat_stream;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
SELECT uuid_generate_v4();

CREATE SCHEMA IF NOT EXISTS audit;

CREATE TYPE audit.job_status AS ENUM (
    'pending',
    'running',
    'complete',
    'failed'
);

CREATE TYPE audit.message_status AS ENUM  (
    'published',
    'consumed',
    'failed'
);

CREATE TYPE audit.api_limit_type AS ENUM (
    'second',
    'minute',
    'hour',
    'day',
    'week',
    'month',
    'year'
);

CREATE TABLE audit.api_list (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    base_url TEXT NOT NULL,
    limit_type audit.api_limit_type NOT NULL,
    rate_limit INT NOT NULL CHECK(rate_limit >= 0),
    next_reset TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(name, base_url)
);

CREATE TABLE audit.api_endpoint_list (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    api_id UUID NOT NULL REFERENCES audit.api_list(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    endpoint TEXT NOT NULL,
    UNIQUE(api_id, endpoint)
);

CREATE TABLE audit.job_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    endpoint_id UUID REFERENCES audit.api_endpoint_list(id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    job_type TEXT NOT NULL,
    status audit.job_status NOT NULL DEFAULT 'pending',
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    error TEXT
);

CREATE TABLE audit.rate_limit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    endpoint_id UUID REFERENCES audit.api_endpoint_list(id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    occurred_at TIMESTAMPTZ DEFAULT NOW(),
    retry_after TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ
);

CREATE TABLE audit.message_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES audit.job_history(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    status audit.message_status NOT NULL,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    occurred_at TIMESTAMPTZ DEFAULT NOW(),
    error TEXT
);

CREATE INDEX ON audit.job_history(status);
CREATE INDEX ON audit.job_history(started_at);
CREATE INDEX ON audit.rate_limit_log(endpoint_id);
CREATE INDEX ON audit.message_log(job_id);
CREATE INDEX ON audit.rate_limit_log(occurred_at);
CREATE INDEX ON audit.rate_limit_log(retry_after);