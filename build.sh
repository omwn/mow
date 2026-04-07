#!/usr/bin/env bash
#
# build.sh — Build the Myanmar Open Wordnet package and Cygnet databases.
#
# Usage: bash build.sh [--rebuild]
#   --rebuild   Wipe the cygnet work directory first (forces re-download of
#               all wordnets — use when wordnets.toml URLs have changed)
#
# Produces:
#   build/wnmow-VERSION.tar.xz     — WordNet LMF package
#   docs/mya-cygnet.db.gz          — Cygnet main database
#   docs/mya-provenance.db.gz      — Cygnet provenance database
#   docs/                          — web UI (serve with: bash run.sh)
#
# Prerequisites: uv, curl, tar, xz, wget, xmlstarlet, python3

set -euo pipefail

VERSION="0.1.3"
TAB_FILE="mow-0.1.3-mya_20171005165336.tab"
DTD="WN-LMF-1.4.dtd"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
CYGNET_DIR="$(cd "$PROJECT_DIR/../cygnet" && pwd)"
CYGNET_WORK="$PROJECT_DIR/build/cygnet-work"

if [[ "${1:-}" == "--rebuild" ]]; then
    echo "Cleaning cygnet work directory for full rebuild..."
    rm -rf "$CYGNET_WORK"
fi

DESCRIPTION="The Myanmar Open Wordnet (MOW) is a freely-available semantic \
dictionary of the Myanmar/Burmese language, part of the Open Multilingual Wordnet. \
It is built using the expand approach from Princeton WordNet synsets."

mkdir -p external

if [ ! -d external/cili ]; then
    echo "Retrieving ILI map"
    git clone https://github.com/globalwordnet/cili.git external/cili
fi

if [ ! -d external/omw-data ]; then
    echo "Retrieving omw-data"
    git clone https://github.com/omwn/omw-data.git external/omw-data
fi

if [ ! -f "external/${DTD}" ]; then
    echo "Retrieving DTD"
    wget "https://globalwordnet.github.io/schemas/${DTD}" -O "external/${DTD}"
fi

uv venv --python 3.11
source .venv/bin/activate
uv pip install -r requirements.txt

citation=$(sed -r -e '/^$/d' -e 's/\s+$//' etc/citation.rst)

NAME="wnmow-${VERSION}"
DIR="build/$NAME"

echo "Preparing package directory"
mkdir -p "$DIR"
cp README.md "$DIR"
cp License.md "$DIR"

echo "Building wordnet XML"
DESTINATION="${DIR}/${NAME}.xml"
# Fix header: MOW tab has 3 fields (label, lang, license) but tsv2lmf.py
# expects 4 (label, lang, url, license).  Insert the URL as field 3.
FIXED_TAB="build/mow-fixed.tab"
{ printf '## MOW 0.1.3\tmya\thttps://github.com/omwn/mow\tCC BY 4.0\n'
  tail -n +2 "$TAB_FILE"
} > "$FIXED_TAB"
pushd external/omw-data/scripts
python3 tsv2lmf.py \
    "$OLDPWD/$FIXED_TAB" \
    "$OLDPWD/$DESTINATION" \
    --id='mow' \
    --label='Myanmar Open Wordnet' \
    --language='my' \
    --version="$VERSION" \
    --email='bond@ieee.org' \
    --license='https://creativecommons.org/licenses/by/4.0/' \
    --url='https://github.com/omwn/mow' \
    --citation="${citation}" \
    --requires=omw-en:2.0 \
    --ili-map="$OLDPWD/external/cili/ili-map-pwn30.tab" \
    --log="$OLDPWD/build/build.log"
popd

xmlstarlet ed -P -L --insert "LexicalResource/Lexicon" \
    -t attr -n dc:description -v "${DESCRIPTION}" "${DESTINATION}"

xmlstarlet ed -P -L --insert "LexicalResource/Lexicon" \
    -t attr -n confidenceScore -v '1.0' "${DESTINATION}"

echo "Validating"
xmlstarlet val -e -d "external/${DTD}" "$DESTINATION"

echo "Archiving the package"
tar -c -J -f "build/${NAME}.tar.xz" "$DIR"

# ============================================================
# CYGNET DATABASE BUILD
# ============================================================
echo ""
echo "=== Building Cygnet databases ==="

mkdir -p "$CYGNET_WORK/bin/raw_wns"

cp "$PROJECT_DIR/etc/wordnets.toml" "$CYGNET_WORK/wordnets.toml"
cp "$PROJECT_DIR/$DESTINATION" "$CYGNET_WORK/bin/raw_wns/${NAME}.xml"

bash "$CYGNET_DIR/build.sh" --work-dir "$CYGNET_WORK"

echo "Deploying to docs/"
mkdir -p "$PROJECT_DIR/docs"
cp "$CYGNET_DIR/web/index.html"          "$PROJECT_DIR/docs/"
cp "$CYGNET_DIR/web/relations.json"      "$PROJECT_DIR/docs/"
cp "$CYGNET_DIR/web/omw-logo.svg"        "$PROJECT_DIR/docs/" 2>/dev/null || true
cp "$PROJECT_DIR/etc/local.json"         "$PROJECT_DIR/docs/"
cp "$CYGNET_WORK/web/cygnet.db.gz"       "$PROJECT_DIR/docs/mya-cygnet.db.gz"
cp "$CYGNET_WORK/web/provenance.db.gz"   "$PROJECT_DIR/docs/mya-provenance.db.gz"

echo ""
echo "=== Build complete ==="
echo "  build/${NAME}.tar.xz     — wordnet package"
echo "  docs/mya-cygnet.db.gz    — Cygnet main database"
echo "  docs/mya-provenance.db.gz — Cygnet provenance database"
echo "  docs/                    — web UI (run with: bash run.sh)"
