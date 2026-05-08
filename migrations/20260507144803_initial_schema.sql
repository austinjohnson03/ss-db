CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS audit;

-- Audit Schema Layout
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

CREATE TABLE audit.job_history (
    id ,
    job_type TEXT NOT NULL,
    status audit.job_status NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ
);

CREATE SCHEMA IF NOT EXISTS cfb;