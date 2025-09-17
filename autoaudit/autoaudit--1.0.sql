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

-- ==========================================
-- Function to attach audit trigger to all existing tables
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

        -- Create trigger
        EXECUTE format('CREATE TRIGGER %I
                        AFTER INSERT OR UPDATE OR DELETE
                        ON %I.%I
                        FOR EACH ROW
                        EXECUTE FUNCTION autoaudit.audit_trigger();',
                        v_trigger_name, r.table_schema, r.table_name);
    END LOOP;
END;
$$;

-- Run it immediately after extension install
SELECT autoaudit.attach_triggers_to_all_tables();

-- ==========================================
-- Event trigger to attach audit to new tables
-- ==========================================
-- Function linked to event trigger
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

-- Create the event trigger
DROP EVENT TRIGGER IF EXISTS autoaudit_attach_new_tables;
CREATE EVENT TRIGGER autoaudit_attach_new_tables
    ON ddl_command_end
    WHEN TAG IN ('CREATE TABLE')
    EXECUTE FUNCTION autoaudit.create_audit_trigger_for_new_table();