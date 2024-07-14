-- Define the schema name
WITH params AS (
    SELECT 'your_schema_name'::text AS schema_name
),
columns AS (
    SELECT
        c.table_name,
        c.column_name,
        c.data_type,
        c.character_maximum_length,
        c.numeric_precision,
        c.numeric_scale,
        c.is_nullable,
        c.column_default
    FROM 
        information_schema.columns c
    JOIN 
        params p ON c.table_schema = p.schema_name
),
constraints AS (
    SELECT
        tc.table_name,
        tc.constraint_name,
        tc.constraint_type,
        kcu.column_name AS constraint_column
    FROM 
        information_schema.table_constraints tc
    JOIN 
        information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    JOIN 
        params p ON tc.table_schema = p.schema_name
),
indexes AS (
    SELECT
        t.relname AS table_name,
        ic.relname AS index_name,
        a.attname AS column_name,
        i.indisunique AS is_unique,
        i.indisprimary AS is_primary
    FROM 
        pg_class t,
        pg_class ic,
        pg_index i,
        pg_attribute a,
        params p
    WHERE 
        t.oid = i.indrelid
        AND ic.oid = i.indexrelid
        AND a.attrelid = t.oid
        AND a.attnum = ANY(i.indkey)
        AND t.relkind = 'r'
        AND t.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = p.schema_name)
),
foreign_keys AS (
    SELECT
        cl.relname AS table_name,
        conname AS constraint_name,
        att2.attname AS column_name,
        cl2.relname AS foreign_table_name,
        att.attname AS foreign_column_name
    FROM 
        (SELECT 
            unnest(con1.conkey) AS parent,
            unnest(con1.confkey) AS child,
            con1.conname,
            con1.confrelid,
            con1.conrelid
        FROM 
            pg_class cl
        JOIN 
            pg_namespace ns ON cl.relnamespace = ns.oid
        JOIN 
            pg_constraint con1 ON con1.conrelid = cl.oid
        JOIN 
            params p ON cl.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = p.schema_name)
        WHERE 
            con1.contype = 'f') con
    JOIN 
        pg_attribute att ON att.attnum = con.child AND att.attrelid = con.confrelid
    JOIN 
        pg_class cl ON cl.oid = con.confrelid
    JOIN 
        pg_class cl2 ON cl2.oid = con.confrelid
    JOIN 
        pg_attribute att2 ON att2.attnum = con.parent AND att2.attrelid = con.conrelid
)
SELECT 
    c.table_name,
    c.column_name,
    c.data_type,
    c.character_maximum_length,
    c.numeric_precision,
    c.numeric_scale,
    c.is_nullable,
    c.column_default,
    co.constraint_name,
    co.constraint_type,
    co.constraint_column,
    i.index_name,
    i.is_unique,
    i.is_primary,
    fk.constraint_name AS foreign_key_constraint,
    fk.column_name AS foreign_key_column,
    fk.foreign_table_name,
    fk.foreign_column_name
FROM 
    columns c
LEFT JOIN 
    constraints co ON c.table_name = co.table_name AND c.column_name = co.constraint_column
LEFT JOIN 
    indexes i ON c.table_name = i.table_name AND c.column_name = i.column_name
LEFT JOIN 
    foreign_keys fk ON c.table_name = fk.table_name AND c.column_name = fk.column_name
ORDER BY 
    c.table_name, c.column_name;
