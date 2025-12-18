#!/usr/bin/env bash
set -euo pipefail

# import_team_images.sh
# Copies team images from a source folder into the iOS app asset catalog,
# converts to PNG with transparency, and names assets `team_<ABBR>.png`.
#
# Usage:
#   ./scripts/import_team_images.sh /path/to/source/teams /path/to/repo/NFLOutcomePredictor/NFLOutcomePredictor/Assets.xcassets
#
# Requirements:
#  - ImageMagick (magick)
#  - Optional: rembg (python package) for higher-quality background removal

SRC_DIR="$1"
ASSETS_DIR="$2"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Source directory not found: $SRC_DIR" >&2
  exit 2
fi

if [[ ! -d "$ASSETS_DIR" ]]; then
  echo "Assets directory not found: $ASSETS_DIR" >&2
  exit 2
fi

echo "Importing team images from: $SRC_DIR"
echo "Destination Assets: $ASSETS_DIR"

process_image() {
  local img="$1"
  local label="$2"
  echo "  Processing $img -> team_${label}.png"

  # mktemp on macOS (BSD) doesn't support --suffix, so create a temp name and append .png
  tmpfile="$(mktemp -t teamimg).png"

  # Convert to PNG and remove backgrounds.
  if command -v magick >/dev/null 2>&1; then
    # Use ImageMagick for conversion
    magick convert "$img" "$tmpfile"

    # Prefer rembg CLI, otherwise fall back to Python module, otherwise do a simple white->transparent pass
    if command -v rembg >/dev/null 2>&1; then
      echo "    Using rembg CLI for background removal"
      rembg i "$tmpfile" "$tmpfile" >/dev/null 2>&1 || true
    elif python3 -c "import rembg" >/dev/null 2>&1; then
      echo "    Using rembg Python module for background removal"
      python3 <<PY >/dev/null 2>&1 || true
from rembg import remove
from pathlib import Path
inp = Path(r"$tmpfile")
data = inp.read_bytes()
out = remove(data)
Path(r"$tmpfile").write_bytes(out)
PY
    else
      echo "    rembg not available — falling back to simple white->transparent pass"
      magick convert "$tmpfile" -fuzz 12% -transparent white "$tmpfile"
    fi

  elif command -v rembg >/dev/null 2>&1 || python3 -c "import rembg" >/dev/null 2>&1; then
    # No ImageMagick available, but rembg (CLI or python) can convert + remove background
    echo "    ImageMagick not found; using rembg for conversion + background removal"
    if command -v rembg >/dev/null 2>&1; then
      rembg i "$img" "$tmpfile" >/dev/null 2>&1 || true
    else
      # Use rembg Python module to convert input -> output
      python3 <<PY >/dev/null 2>&1 || true
from rembg import remove
from pathlib import Path
inp = Path(r"$img")
data = inp.read_bytes()
out = remove(data)
Path(r"$tmpfile").write_bytes(out)
PY
    fi

  else
    echo "  ImageMagick (magick) not found and rembg not available. Install 'brew install imagemagick' or 'pip install rembg'." >&2
    exit 2
  fi

  # Prepare asset folder
  assetname="team_${label}.imageset"
  mkdir -p "$ASSETS_DIR/$assetname"
  cp "$tmpfile" "$ASSETS_DIR/$assetname/100.png"

  cat > "$ASSETS_DIR/$assetname/Contents.json" <<JSON
{
  "images" : [
    {
      "idiom" : "universal",
      "filename" : "100.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
JSON

  rm -f "$tmpfile"
}

# Mapping from common substrings in filenames to team abbreviations
# Format: token:ABBR
TEAM_PAIRS=(
  "arizona:ARI" "cardinals:ARI" "az:ARI"
  "atlanta:ATL" "falcons:ATL"
  "baltimore:BAL" "ravens:BAL"
  "buffalo:BUF" "bills:BUF"
  "carolina:CAR" "panthers:CAR"
  "chicago:CHI" "bears:CHI"
  "cincinnati:CIN" "bengals:CIN"
  "cleveland:CLE" "browns:CLE"
  "dallas:DAL" "cowboys:DAL"
  "denver:DEN" "broncos:DEN"
  "detroit:DET" "lions:DET"
  "greenbay:GB" "green:GB" "packers:GB"
  "houston:HOU" "texans:HOU"
  "indianapolis:IND" "colts:IND"
  "jacksonville:JAX" "jaguars:JAX"
  "kansas:KC" "kansascity:KC" "chiefs:KC"
  "lasvegas:LV" "raiders:LV"
  "losangeleschargers:LAC" "chargers:LAC" "lac:LAC"
  "losangelesrams:LAR" "rams:LAR"
  "miami:MIA" "dolphins:MIA"
  "minnesota:MIN" "vikings:MIN"
  "newengland:NE" "patriots:NE"
  "neworleans:NO" "saints:NO"
  "newyorkgiants:NYG" "giants:NYG"
  "newyorkjets:NYJ" "jets:NYJ"
  "philadelphia:PHI" "eagles:PHI"
  "pittsburgh:PIT" "steelers:PIT"
  "sanfrancisco:SF" "49ers:SF" "niners:SF"
  "seattle:SEA" "seahawks:SEA"
  "tampabay:TB" "buccaneers:TB"
  "tennessee:TEN" "titans:TEN"
  "washington:WAS" "commanders:WAS"
)

# First process images in subfolders (old behavior)
for teamdir in "$SRC_DIR"/*/; do
  if [[ -d "$teamdir" ]]; then
    dirname=$(basename "$teamdir")
    # Try to find an abbreviation token
    if [[ "$dirname" =~ ([A-Z]{2,3})$ ]]; then
      abbr=${BASH_REMATCH[1]}
    else
      # fallback: try to detect a substring match in TEAM_MAP
      key=$(echo "$dirname" | tr '[:upper:]' '[:lower:]')
      found=""
      for pair in "${TEAM_PAIRS[@]}"; do
        token=${pair%%:*}
        ab=${pair##*:}
        if [[ "$key" == *"$token"* ]]; then
          found=$ab
          break
        fi
      done
      abbr=${found:-$(echo "$dirname" | tr '[:upper:]' '[:lower:]')}
    fi

    img=$(ls "$teamdir"*.{webp,jpg,jpeg,png} 2>/dev/null | head -n1 || true)
    if [[ -n "$img" ]]; then
      process_image "$img" "$abbr"
    fi
  fi
done

# Then process images directly in the source directory
for img in "$SRC_DIR"/*.{webp,jpg,jpeg,png}; do
  [[ -e "$img" ]] || continue
  filename=$(basename "$img" | tr '[:upper:]' '[:lower:]')
  found=""
  for pair in "${TEAM_PAIRS[@]}"; do
    token=${pair%%:*}
    ab=${pair##*:}
    if [[ "$filename" == *"$token"* ]]; then
      found=$ab
      break
    fi
  done
  if [[ -z "$found" ]]; then
    echo "  No mapping for $filename — skipping"
    continue
  fi
  process_image "$img" "$found"
done

echo "Import complete. Open Xcode and refresh the asset catalog (or run a build)."
