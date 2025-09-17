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

-- ==========================================
-- Generic audit trigger function
-- ==========================================
CREATE OR REPLACE FUNCTION autoaudit.audit_trigger()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_old JSONB;
    v_new JSONB;
BEGIN
    -- Convert OLD and NEW into JSONB if they exist
    IF (TG_OP = 'DELETE') THEN
        v_old := to_jsonb(OLD);
        v_new := NULL;
    ELSIF (TG_OP = 'UPDATE') THEN
        v_old := to_jsonb(OLD);
        v_new := to_jsonb(NEW);
    ELSIF (TG_OP = 'INSERT') THEN
        v_old := NULL;
        v_new := to_jsonb(NEW);
    END IF;

    -- Insert log into audit table
    INSERT INTO autoaudit.audit_log (
        operation_type,
        table_name,
        executed_by,
        client_ip,
        old_data,
        new_data
    )
    VALUES (
        TG_OP,              -- INSERT, UPDATE, DELETE
        TG_TABLE_NAME,      -- table affected
        current_user,       -- user executing
        inet_client_addr(), -- client IP
        v_old,
        v_new
    );

    -- For INSERT/UPDATE return NEW, for DELETE return OLD
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;