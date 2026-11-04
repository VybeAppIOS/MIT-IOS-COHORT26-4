# How to add a Place or a Hangout (task X-C4)

Content lives in one Google Sheet. The script `scripts/import_content.py` turns it into the app's JSON files and checks
everything first. You never write JSON by hand.

## The rules (`AGENTS.md` 4, `docs/PRODUCT.md` 8)
- **Only real places you have been to.** Name, address, coordinates, hours and prices come from your visit.
- **Never copy from Apple Maps or Google Maps** (their terms forbid it). For coordinates, stand at the entrance and note
  your phone's own location (for example in the Compass app). Never paste anything from a map listing.
- **Photos you took**, with the person's OK, at most 3 per Place, each with a `credit`. Before adding a photo, run it
  through the app's photo step or any tool that removes location data, and keep it under about 300 KB.
- No homes or private addresses. A trek gets all four trek columns, including a safety note.

## The Sheet: five tabs (copy the example rows in `docs/content-template/`)
| Tab | One row per | Key columns |
|---|---|---|
| Places | Place | `id` (`place-<name>-<4 random letters or digits>`, never changed once used), `category` (one of the list the script prints), `latitude`, `longitude` (inside Pune), `cost_lower`, `cost_upper` (₹ per person), `verified_on` (the day you checked it) |
| PlaceHours | opening window | `weekday` 1 = Sunday … 7 = Saturday, `open` and `close` like `09:30` |
| PlacePhotos | photo | `file` (the name of the photo in `VybeKit/Sources/LocalData/Resources/Content/Photos/`), `credit` |
| Hangouts | Hangout | `id` (`hangout-<name>-<4>`), `budget_lower`/`budget_upper`, `estimated_minutes`, lists separated by `\|` |
| Spots | Spot | one row per Spot, **in visiting order**; 2 to 10 per Hangout |

## Steps
1. Fill the rows in the Sheet. Put the photo files in `VybeKit/Sources/LocalData/Resources/Content/Photos/`.
2. Download each tab as CSV (File › Download › CSV) into one folder, named exactly `Places.csv`, `PlaceHours.csv`,
   `PlacePhotos.csv`, `Hangouts.csv`, `Spots.csv`.
3. Check: `python3 scripts/import_content.py <that folder> --check`. Every problem is listed with its tab and row number;
   fix them in the Sheet and download again.
4. Write: `python3 scripts/import_content.py <that folder>`. Then run `./scripts/check.sh` (the content test) and open a PR
   (`X-C2: add 15 Kothrud Places`).
