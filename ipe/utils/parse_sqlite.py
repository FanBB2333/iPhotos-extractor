import sqlite3
import os
import json

db_file = r"~/Pictures/Photos Library.photoslibrary/database/Photos.sqlite"
# db_file = r"~/Library/Group Containers/group.com.apple.notes/NoteStore.sqlite"
# db_file = r"NoteStore.sqlite"
db_file = r"./test/test1.photoslibrary/database/Photos.sqlite"
# parse home dir
db_file = os.path.expanduser(db_file)

def inspect_tables():
    conn = sqlite3.connect(db_file)
    c = conn.cursor()

    c.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = c.fetchall()

    table_info = {}

    for table in tables:
        table_name = table[0]
        c.execute(f"SELECT COUNT(*) FROM {table_name}")
        row_count = c.fetchone()[0]
        table_info[table_name] = row_count

    conn.close()

    with open("table_info.json", "w") as f:
        json.dump(table_info, f, indent=4)


def print_table_columns(table_name):
    conn = sqlite3.connect(db_file)
    c = conn.cursor()

    try:
        c.execute(f"PRAGMA table_info({table_name})")
        columns = c.fetchall()

        print(f"Column names for table {table_name}:")
        for column in columns:
            print(f"Column: {column[1]}, Type: {column[2]}")

    except sqlite3.OperationalError as e:
        print(f"Error accessing table {table_name}: {e}")

    conn.close()

def print_table_content(table_name, n=None):
    conn = sqlite3.connect(db_file)
    c = conn.cursor()

    try:
        c.execute(f"SELECT * FROM {table_name}")
        rows = c.fetchall()

        if n is None:
            to_print = rows
        else:
            to_print = rows[:n]

        print(f"Contents of table {table_name} (showing up to {n if n else 'all'} rows):")
        for row in to_print:
            print(row)

    except sqlite3.OperationalError as e:
        print(f"Error accessing table {table_name}: {e}")

    conn.close()

if __name__ == "__main__":
    inspect_tables()
    # print_table_columns('ZALBUMLIST')
    # print_table_columns('ZASSET')
    # print_table_content('ZASSET', 10)
    