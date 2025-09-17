-- ==============================================================
-- EXTENSION: AutoAudit
-- VERSION: 1.0
-- Authors: Jairo Jesus Gonzalez, Rafael Odio Mendoza, Maria Paula Castillo Chinchilla, Aaron Lios Cubillo
-- Course: "Bases de Datos II"
--
-- Description:
--   This extension adds automatic auditing capabilities
--   to PostgreSQL databases. It records all INSERT, UPDATE,
--   and DELETE operations executed by any user on any table
--   in the database (except system schemas and the audit schema).
--
--   Security and Integrity notes:
--   - Creates and uses a dedicated schema: "autoaudit".
--   - The trigger function is defined with SECURITY DEFINER,
--     so auditing works without requiring explicit GRANTs
--     on the audit_log table for every user.
--   - Each event stores: operation type, table name,
--     user who executed it, client IP, and row data (before/after).
-- ==============================================================

-- ==========================================
-- Create the centralized audit log table
-- ==========================================
-- Purpose:
--   Stores all audit events in a single table.
-- Columns:
--   event_id       : auto-incremented unique identifier
--   operation_type : type of operation (INSERT, UPDATE, DELETE)
--   table_name     : affected table
--   event_time     : exact timestamp of the operation
--   executed_by    : role/user who executed the statement
--   client_ip      : IP of the client session
--   old_data       : row state before the operation (JSONB)
--   new_data       : row state after  the operation (JSONB)
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
-- Generic Audit Trigger Function
-- ------------------------------------------
-- Name : audit_trigger()
-- Type : AFTER ROW trigger (INSERT, UPDATE, DELETE)
-- Security:
--   SECURITY DEFINER ensures that the function
--   inserts into audit_log with the privileges of
--   the function owner (typically postgres).
--   This avoids granting INSERT privileges on audit_log
--   to every regular user of the database.
-- Behavior:
--   - Detects the operation type (INSERT, UPDATE, DELETE)
--   - Captures OLD and NEW row states as JSONB
--   - Inserts a row into audit_log with:
--       * operation type
--       * affected table
--       * session user
--       * client IP
--       * old/new row data
--   - Returns NEW for INSERT/UPDATE or OLD for DELETE
-- ==========================================
CREATE OR REPLACE FUNCTION autoaudit.audit_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
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
        TG_OP,              -- Operation: INSERT, UPDATE, DELETE
        TG_TABLE_NAME,      -- Affected table
        SESSION_USER,       -- User/role executing the statement
        inet_client_addr(), -- client connection IP
        v_old,              -- Row state before the operation
        v_new               -- Row state after the operation
    );

    -- For INSERT/UPDATE return NEW, for DELETE return OLD
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

-- ==========================================
-- Function to attach audit trigger to all existing tables
-- ==========================================
-- Purpose:
--   Automatically applies the audit_trigger()
--   function to all existing base tables in
--   the database (excluding system schemas
--   and the autoaudit schema).
-- Behavior:
--   - Iterates over user tables
--   - Drops old audit trigger if it exists
--   - Creates a new audit trigger with name pattern: audit_<table>
-- ==========================================
CREATE OR REPLACE FUNCTION autoaudit.attach_triggers_to_all_tables()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
    v_trigger_name TEXT;
BEGIN
    FOR r IN
        SELECT table_schema, table_name
        FROM information_schema.tables
        WHERE table_type = 'BASE TABLE'
          AND table_schema NOT IN ('pg_catalog', 'information_schema', 'autoaudit')
    LOOP
        v_trigger_name := 'audit_' || r.table_name;

        -- Drop trigger if already exists
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I;',
                        v_trigger_name, r.table_schema, r.table_name);

        -- Create trigger linked to audit_trigger()
        EXECUTE format('CREATE TRIGGER %I
                        AFTER INSERT OR UPDATE OR DELETE
                        ON %I.%I
                        FOR EACH ROW
                        EXECUTE FUNCTION autoaudit.audit_trigger();',
                        v_trigger_name, r.table_schema, r.table_name);
    END LOOP;
END;
$$;
-- Execute immediately after extension is installed
SELECT autoaudit.attach_triggers_to_all_tables();

-- ==========================================
-- Event trigger to attach audit to new tables
-- ==========================================
-- Purpose:
--   Ensures that any new table created after
--   installing the extension automatically
--   receives an audit trigger.
-- Behavior:
--   - Captures CREATE TABLE DDL events
--   - Dynamically attaches an audit trigger
--     invoking audit_trigger() to the new table
-- ==========================================
CREATE OR REPLACE FUNCTION autoaudit.create_audit_trigger_for_new_table()
RETURNS event_trigger
LANGUAGE plpgsql
AS $$
DECLARE
    obj record;
    v_trigger_name TEXT;
BEGIN
    FOR obj IN
        SELECT * FROM pg_event_trigger_ddl_commands()
        WHERE command_tag = 'CREATE TABLE'
    LOOP
        v_trigger_name := 'audit_' || obj.object_identity;

        EXECUTE format('CREATE TRIGGER %I
                        AFTER INSERT OR UPDATE OR DELETE
                        ON %s
                        FOR EACH ROW
                        EXECUTE FUNCTION autoaudit.audit_trigger();',
                        v_trigger_name, obj.object_identity);
    END LOOP;
END;
$$;
-- Create the event trigger itself
DROP EVENT TRIGGER IF EXISTS autoaudit_attach_new_tables;
CREATE EVENT TRIGGER autoaudit_attach_new_tables
    ON ddl_command_end
    WHEN TAG IN ('CREATE TABLE')
    EXECUTE FUNCTION autoaudit.create_audit_trigger_for_new_table();