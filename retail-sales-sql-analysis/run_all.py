"""Runs every query in /queries against retail.db and prints the results."""
import sqlite3, re, glob
con = sqlite3.connect("retail.db")
for path in sorted(glob.glob("queries/*.sql")):
    text = open(path).read()
    for block in re.split(r"(?=^-- Q\d+\.)", text, flags=re.M):
        m = re.match(r"-- (Q\d+\..*)", block)
        if not m: continue
        cur = con.execute(block)
        cols = [d[0] for d in cur.description]
        print(f"\n### {m.group(1)}\n{cols}")
        for row in cur.fetchall()[:15]: print(row)
