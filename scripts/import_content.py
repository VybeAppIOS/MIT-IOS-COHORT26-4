#!/usr/bin/env python3
"""Turns the content Google Sheet into the app's JSON files (task X-C4). Standard library only (AGENTS.md section 4).

  python3 scripts/import_content.py <folder with the CSV files>              check, then write the JSON files
  python3 scripts/import_content.py <folder> --check                         check only, write nothing
  python3 scripts/import_content.py <folder> --out <folder>                  write somewhere else (default: the app)

The Sheet has five tabs; export each one as CSV (File > Download > CSV) into one folder, named exactly:
  Places.csv       id, name, category, city, area, address, latitude, longitude, cost_lower, cost_upper, hours_note,
                   apple_place_id, status, verified_on, trek_difficulty, trek_season, trek_start_point, trek_safety_note
  PlaceHours.csv   place_id, weekday (1 = Sunday … 7 = Saturday), open (HH:mm), close (HH:mm)
  PlacePhotos.csv  place_id, photo_id, file, width, height, credit
  Hangouts.csv     id, title, summary, budget_lower, budget_upper, estimated_minutes, best_times, tags, vibe_tags,
                   author_id, is_pick, status, remixed_from_id, remixed_from_place_ids, created_on, updated_on
  Spots.csv        hangout_id, spot_id, place_id, minutes, note        (rows in visiting order)
Lists inside a cell (best_times, tags, vibe_tags, remixed_from_place_ids) are separated by "|".
A guide for teammates: docs/ADD-A-PLACE.md. Example rows: docs/content-template/.

Every problem is reported with its file and row number, and nothing is written while there is any problem:
IDs (format, unique), categories, Pune bounds, 2 to 10 Spots, every Spot's Place exists, photo files exist and have
a credit, at most 3 photos per Place, numbers and dates are valid. Data must be real and checked by a person who went
there; never copied from Apple Maps or Google Maps (AGENTS.md section 4).
"""
import argparse
import csv
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_OUT = os.path.join(ROOT, "VybeKit/Sources/LocalData/Resources/Content")
CATEGORY_FILE = os.path.join(ROOT, "VybeKit/Sources/Models/Content/PlaceCategory.swift")
SCHEMA_VERSION = 1
LATITUDE = (18.3, 18.7)
LONGITUDE = (73.6, 74.1)
PLACE_ID = re.compile(r"^place-[a-z0-9]+(?:-[a-z0-9]+)*-[a-z0-9]{4}$")
HANGOUT_ID = re.compile(r"^hangout-[a-z0-9]+(?:-[a-z0-9]+)*-[a-z0-9]{4}$")
TIME = re.compile(r"^(?:[01]\d|2[0-3]):[0-5]\d$")
DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
FULL_TIME = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")
STATUSES = {"approved", "hidden", "closedByAuthorities"}
HANGOUT_STATUSES = {"draft", "published"}
DIFFICULTIES = {"easy", "moderate", "hard", "unknown"}
MAX_PHOTOS = 3


class Problems:
    def __init__(self):
        self.items = []

    def add(self, where, message):
        self.items.append(f"{where}: {message}")


def categories():
    """The raw values of PlaceCategory, read from the Swift file so the two can never drift apart."""
    source = open(CATEGORY_FILE, encoding="utf-8").read()
    names = re.findall(r'^\s*case (\w+)(?: = "([a-z-]+)")?\s*$', source, re.M)
    return {raw or name for name, raw in names} - {"unknown"}


def read(folder, name, problems):
    path = os.path.join(folder, name)
    if not os.path.exists(path):
        problems.add(name, "file not found (export that tab of the Sheet as CSV with exactly this name)")
        return []
    with open(path, newline="", encoding="utf-8-sig") as handle:
        # Row 1 is the header, so the first data row is row 2, as the Sheet shows it.
        return [(index + 2, {k.strip(): (v or "").strip() for k, v in row.items() if k})
                for index, row in enumerate(csv.DictReader(handle))]


def number(value, where, field, problems, kind=int, required=True):
    if value == "":
        if required:
            problems.add(where, f"{field} is empty")
        return None
    try:
        return kind(value)
    except ValueError:
        problems.add(where, f"{field} '{value}' is not a number")
        return None


def timestamp(value, where, field, problems):
    """A date (2026-11-03, stored as midnight UTC) or a full UTC time (2026-11-03T10:00:00Z)."""
    if DATE.match(value):
        return f"{value}T00:00:00Z"
    if FULL_TIME.match(value):
        return value
    problems.add(where, f"{field} '{value}' must be a date like 2026-11-03")
    return None


def split(value):
    return [part.strip() for part in value.split("|") if part.strip()]


def build_places(folder, problems):
    known = categories()
    places, order = {}, []
    for row_number, row in read(folder, "Places.csv", problems):
        where = f"Places.csv row {row_number}"
        place_id = row.get("id", "")
        if not PLACE_ID.match(place_id):
            problems.add(where, f"id '{place_id}' must look like place-<name>-<4 letters or digits>")
        if place_id in places:
            problems.add(where, f"id '{place_id}' is used twice")
        for field in ("name", "city", "area", "address"):
            if not row.get(field):
                problems.add(where, f"{field} is empty")
        if row.get("category") not in known:
            problems.add(where, f"category '{row.get('category')}' is not one of: {', '.join(sorted(known))}")
        latitude = number(row.get("latitude", ""), where, "latitude", problems, float)
        longitude = number(row.get("longitude", ""), where, "longitude", problems, float)
        if latitude is not None and not LATITUDE[0] <= latitude <= LATITUDE[1]:
            problems.add(where, f"latitude {latitude} is outside Pune ({LATITUDE[0]} to {LATITUDE[1]})")
        if longitude is not None and not LONGITUDE[0] <= longitude <= LONGITUDE[1]:
            problems.add(where, f"longitude {longitude} is outside Pune ({LONGITUDE[0]} to {LONGITUDE[1]})")
        lower = number(row.get("cost_lower", ""), where, "cost_lower", problems)
        upper = number(row.get("cost_upper", ""), where, "cost_upper", problems)
        if lower is not None and upper is not None and not 0 <= lower <= upper:
            problems.add(where, "cost must be 0 or more, and cost_lower must not be above cost_upper")
        status = row.get("status") or "approved"
        if status not in STATUSES:
            problems.add(where, f"status '{status}' is not one of: {', '.join(sorted(STATUSES))}")
        place = {
            "schemaVersion": SCHEMA_VERSION, "id": place_id, "name": row.get("name", ""),
            "category": row.get("category", ""), "city": row.get("city", ""), "area": row.get("area", ""),
            "address": row.get("address", ""), "coordinate": {"latitude": latitude, "longitude": longitude},
            "costPerPerson": {"lower": lower, "upper": upper}, "hours": [], "hoursNote": row.get("hours_note") or None,
            "photos": [], "applePlaceID": row.get("apple_place_id") or None, "status": status,
            "verifiedAt": timestamp(row.get("verified_on", ""), where, "verified_on", problems),
        }
        trek = trek_info(row, where, problems)
        if trek:
            place["trekInfo"] = trek
        places[place_id] = place
        order.append(place_id)
    return places, order


def trek_info(row, where, problems):
    fields = ("trek_difficulty", "trek_season", "trek_start_point", "trek_safety_note")
    if not any(row.get(field) for field in fields):
        return None
    if not all(row.get(field) for field in fields):
        problems.add(where, "a trek needs all four trek columns (difficulty, season, start point, safety note)")
    if row.get("trek_difficulty") and row["trek_difficulty"] not in DIFFICULTIES:
        problems.add(where, f"trek_difficulty must be one of: {', '.join(sorted(DIFFICULTIES))}")
    return {"difficulty": row.get("trek_difficulty", ""), "season": row.get("trek_season", ""),
            "startPoint": row.get("trek_start_point", ""), "safetyNote": row.get("trek_safety_note", "")}


def add_hours(folder, places, problems):
    for row_number, row in read(folder, "PlaceHours.csv", problems):
        where = f"PlaceHours.csv row {row_number}"
        place = places.get(row.get("place_id", ""))
        if place is None:
            problems.add(where, f"place_id '{row.get('place_id')}' is not in Places.csv")
            continue
        weekday = number(row.get("weekday", ""), where, "weekday", problems)
        if weekday is not None and not 1 <= weekday <= 7:
            problems.add(where, "weekday must be 1 (Sunday) to 7 (Saturday)")
        for field in ("open", "close"):
            if not TIME.match(row.get(field, "")):
                problems.add(where, f"{field} '{row.get(field)}' must be a time like 09:30")
        place["hours"].append({"weekday": weekday, "open": row.get("open"), "close": row.get("close")})


def add_photos(folder, places, photos_folder, problems):
    for row_number, row in read(folder, "PlacePhotos.csv", problems):
        where = f"PlacePhotos.csv row {row_number}"
        place = places.get(row.get("place_id", ""))
        if place is None:
            problems.add(where, f"place_id '{row.get('place_id')}' is not in Places.csv")
            continue
        if not row.get("credit"):
            problems.add(where, "every photo needs a credit (who took it, with their OK)")
        if not row.get("photo_id"):
            problems.add(where, "photo_id is empty")
        file_name = row.get("file", "")
        if not os.path.exists(os.path.join(photos_folder, file_name)) or not file_name:
            problems.add(where, f"photo file '{file_name}' is not in {os.path.relpath(photos_folder, ROOT)}")
        if len(place["photos"]) >= MAX_PHOTOS:
            problems.add(where, f"at most {MAX_PHOTOS} photos per Place in the app (keep the rest for the backend)")
        place["photos"].append({
            "id": row.get("photo_id", ""), "path": file_name, "credit": row.get("credit") or None,
            "width": number(row.get("width", ""), where, "width", problems),
            "height": number(row.get("height", ""), where, "height", problems),
        })


def build_hangouts(folder, places, problems):
    hangouts, order = {}, []
    for row_number, row in read(folder, "Hangouts.csv", problems):
        where = f"Hangouts.csv row {row_number}"
        hangout_id = row.get("id", "")
        if not HANGOUT_ID.match(hangout_id):
            problems.add(where, f"id '{hangout_id}' must look like hangout-<name>-<4 letters or digits>")
        if hangout_id in hangouts:
            problems.add(where, f"id '{hangout_id}' is used twice")
        for field in ("title", "summary", "author_id"):
            if not row.get(field):
                problems.add(where, f"{field} is empty")
        lower = number(row.get("budget_lower", ""), where, "budget_lower", problems)
        upper = number(row.get("budget_upper", ""), where, "budget_upper", problems)
        if lower is not None and upper is not None and not 0 <= lower <= upper:
            problems.add(where, "budget must be 0 or more, and budget_lower must not be above budget_upper")
        status = row.get("status") or "published"
        if status not in HANGOUT_STATUSES:
            problems.add(where, f"status '{status}' is not draft or published")
        if row.get("is_pick", "").lower() not in ("", "true", "false", "yes", "no"):
            problems.add(where, "is_pick must be true or false")
        remixed_from_places = split(row.get("remixed_from_place_ids", ""))
        for place_id in remixed_from_places:
            if place_id not in places:
                problems.add(where, f"remixed_from_place_ids names '{place_id}', which is not in Places.csv")
        hangouts[hangout_id] = {
            "schemaVersion": SCHEMA_VERSION, "id": hangout_id, "title": row.get("title", ""),
            "summary": row.get("summary", ""), "spots": [], "budgetPerPerson": {"lower": lower, "upper": upper},
            "estimatedMinutes": number(row.get("estimated_minutes", ""), where, "estimated_minutes", problems),
            "bestTimes": split(row.get("best_times", "")), "tags": split(row.get("tags", "")),
            "vibeTags": split(row.get("vibe_tags", "")), "authorID": row.get("author_id", ""),
            "isPick": row.get("is_pick", "").lower() in ("true", "yes"), "status": status,
            "remixedFromID": row.get("remixed_from_id") or None,
            "remixedFromPlaceIDs": remixed_from_places or None,
            "createdAt": timestamp(row.get("created_on", ""), where, "created_on", problems),
            "updatedAt": timestamp(row.get("updated_on", ""), where, "updated_on", problems),
        }
        order.append(hangout_id)
    return hangouts, order


def add_spots(folder, places, hangouts, problems):
    for row_number, row in read(folder, "Spots.csv", problems):
        where = f"Spots.csv row {row_number}"
        hangout = hangouts.get(row.get("hangout_id", ""))
        if hangout is None:
            problems.add(where, f"hangout_id '{row.get('hangout_id')}' is not in Hangouts.csv")
            continue
        if row.get("place_id") not in places:
            problems.add(where, f"place_id '{row.get('place_id')}' is not in Places.csv")
        spot_id = row.get("spot_id", "")
        if not spot_id or any(spot["id"] == spot_id for spot in hangout["spots"]):
            problems.add(where, f"spot_id '{spot_id}' is empty or used twice in {hangout['id']}")
        hangout["spots"].append({
            "id": spot_id, "placeID": row.get("place_id", ""),
            "minutes": number(row.get("minutes", ""), where, "minutes", problems, required=False),
            "note": row.get("note") or None,
        })
    for hangout in hangouts.values():
        if not 2 <= len(hangout["spots"]) <= 10:
            problems.add(f"Hangouts.csv {hangout['id']}", f"has {len(hangout['spots'])} Spots; it needs 2 to 10")


def write(folder, name, value):
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, f"{name}.json"), "w", encoding="utf-8") as handle:
        # Sorted keys and two-space indents, like the app's own JSONCoding, so diffs stay small.
        handle.write(json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n")


def main():
    parser = argparse.ArgumentParser(description="Content Sheet (CSV tabs) → the app's JSON files (task X-C4).")
    parser.add_argument("folder", help="the folder with Places.csv, PlaceHours.csv, PlacePhotos.csv, Hangouts.csv, "
                                       "Spots.csv")
    parser.add_argument("--out", default=DEFAULT_OUT, help="where the Places/ and Hangouts/ folders go")
    parser.add_argument("--check", action="store_true", help="check only; write nothing")
    args = parser.parse_args()

    problems = Problems()
    places, place_order = build_places(args.folder, problems)
    add_hours(args.folder, places, problems)
    add_photos(args.folder, places, os.path.join(args.out, "Photos"), problems)
    hangouts, hangout_order = build_hangouts(args.folder, places, problems)
    add_spots(args.folder, places, hangouts, problems)

    if problems.items:
        print(f"{len(problems.items)} problem(s); nothing was written:", file=sys.stderr)
        for item in problems.items:
            print(f"  {item}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: {len(places)} Places, {len(hangouts)} Hangouts, every check passed.")
    if args.check:
        return
    for place_id in place_order:
        write(os.path.join(args.out, "Places"), place_id, places[place_id])
    for hangout_id in hangout_order:
        write(os.path.join(args.out, "Hangouts"), hangout_id, hangouts[hangout_id])
    print(f"Wrote them to {os.path.relpath(args.out, ROOT)}. Next: run ./scripts/check.sh (the content test).")


if __name__ == "__main__":
    main()
