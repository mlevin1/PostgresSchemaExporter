import json
import psycopg2
import csv

# Load the database configuration from the JSON file
with open('db_config.json', 'r') as config_file:
    config = json.load(config_file)

# Connect to the PostgreSQL database
conn = psycopg2.connect(
    host=config['host'],
    port=config['port'],
    database=config['database'],
    user=config['user'],
    password=config['password']
)

# Read the SQL script
with open('extract_table_info.sql', 'r') as sql_file:
    sql_script = sql_file.read()

# Replace the placeholder with the actual schema name
sql_script = sql_script.replace('your_schema_name', config['schema'])

# Execute the SQL script
cur = conn.cursor()
cur.execute(sql_script)
rows = cur.fetchall()
print(rows)  # Add this line to check the output

# Fetch all results
results = cur.fetchall()

# Get column names
column_names = [desc[0] for desc in cur.description]

# Define CSV file headers
headers = [
    'table_name', 'column_name', 'data_type', 'character_maximum_length',
    'numeric_precision', 'numeric_scale', 'is_nullable', 'column_default',
    'constraint_name', 'constraint_type', 'constraint_column', 'index_name',
    'is_unique', 'is_primary', 'foreign_key_constraint', 'foreign_key_column',
    'foreign_table_name', 'foreign_column_name'
]

# Write results to CSV file
with open('table_info.csv', 'w', newline='') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(headers)
    writer.writerows(rows)


# Close the cursor and connection
cur.close()
conn.close()