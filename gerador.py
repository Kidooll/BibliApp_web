import csv

seen = set()
rows = []
with open("reading_plan_items_final.csv", newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for r in reader:
        key = (r["reading_plan_id"], r["day_number"], r["chapter_number"])
        if key in seen:
            continue
        seen.add(key)
        rows.append(r)

with open("reading_plan_items_final_dedup.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=reader.fieldnames)
    writer.writeheader()
    writer.writerows(rows)

print("Linhas únicas:", len(rows))
