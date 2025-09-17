# PostgreSQL-AutoAudit
This project contributes to the PostgreSQL open-source ecosystem through an extension called AutoAudit. Its purpose is to provide databases with self-auditing capabilities, automatically recording all operations performed by different users on any table in the database.

The extension creates an exclusive schema, accessible only by the user who invokes its installation, thereby ensuring the security and integrity of the created objects (tables, views, functions, triggers, etc.).

All generated functions are immutable after their creation, ensuring they cannot be modified or tampered with once installed.

The auditing is comprehensive, recording the following data for each operation in a centralized table:

    Unique event identifier
    Type of operation (INSERT, UPDATE, DELETE)
    Name of the affected table
    Exact date and time of the event
    User executing the operation
    Client IP address
    Previous state of the data (before the modification)
    New state of the data (after the modification)
