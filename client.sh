#!/usr/bin/env bash
./node_modules/coffee-script/bin/coffee --bare --output public/js/ chaplin/
cp chaplin/templates/*.eco public/js/templates
(cd public/js/templates ; find . -type f \( -iname '*.eco' \) -exec ../../../node_modules/eco/bin/eco {} -o . -i "JST" \; -exec rm -rf {} \;)