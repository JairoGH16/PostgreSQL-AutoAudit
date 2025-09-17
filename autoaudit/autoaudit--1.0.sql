-- autoaudit--1.0.sql
-- Initial version of AutoAudit extension
-- This extension adds automatic auditing functionality to PostgreSQL databases.

-- ==========================================
-- Create the centralized audit log table
-- ==========================================
CREATE TABLE autoaudit.audit_log (
    event_id       BIGSERIAL PRIMARY KEY,
    operation_type TEXT NOT NULL,  -- INSERT, UPDATE, DELETE
    table_name     TEXT NOT NULL,
    event_time     TIMESTAMPTZ NOT NULL DEFAULT now(),
    executed_by    TEXT NOT NULL,  -- current_user
    client_ip      INET,           -- client connection ip
    old_data       JSONB,
    new_data       JSONB
);

