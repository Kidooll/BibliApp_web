import json, csv, pathlib

base = pathlib.Path("bibli_app/assets/reading_plans")
out = open("reading_plan_items.csv", "w", newline="", encoding="utf-8")
writer = csv.writer(out)
writer.writerow(["plan_title","plan_description","duration_days","day_number","book_name","chapter_start","chapter_end"])

for path in sorted(base.glob("*.json")):
    data = json.loads(path.read_text(encoding="utf-8"))
    title = data.get("title","")
    desc = data.get("description","")
    duration = data.get("duration_days", 0)
    for item in data.get("chapters", []):
        day = item.get("dia")
        book = item.get("book_name","")
        start = item.get("chapter_start")
        end = item.get("chapter_end", start)
        writer.writerow([title, desc, duration, day, book, start, end])
out.close()
print("Gerado reading_plan_items.csv")
