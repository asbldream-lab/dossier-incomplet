#!/bin/bash
# Exporte la version web et la publie sur GitHub Pages (branche gh-pages).
set -e
cd "$(dirname "$0")/.."
GODOT=~/Downloads/Godot.app/Contents/MacOS/Godot
rm -rf build/web && mkdir -p build/web
$GODOT --headless --path . --export-release "Web" build/web/index.html > /dev/null 2>&1
touch build/web/.nojekyll
cd build/web
rm -rf .git && git init -q -b gh-pages && git add -A
git commit -q -m "Version web $(date '+%Y-%m-%d %H:%M')"
git push -q -f https://github.com/asbldream-lab/dossier-incomplet.git gh-pages
rm -rf .git
echo "Publié : https://asbldream-lab.github.io/dossier-incomplet/"
