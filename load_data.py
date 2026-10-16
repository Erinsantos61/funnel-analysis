# load_data.py
# Purpose: load the raw events CSV into a SQLite database so SQL can query it.
# Run once from the project folder:  python load_data.py

import pandas as pd
import sqlite3

CSV_PATH = "data/events.csv"  # raw data file
DB_PATH = "data/funnel.db"  # database file this script creates

df = pd.read_csv(CSV_PATH)                 # read the CSV into a table in memory
conn = sqlite3.connect(DB_PATH)            # open (or create) the database file

# Write the data to a table called "events", replacing it if it already exists
df.to_sql("events", conn, if_exists="replace", index=False)

conn.close()                               # always close the connection
print(f"Loaded {len(df):,} rows into events")
