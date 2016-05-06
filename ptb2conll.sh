#!/bin/bash

set -e
set -u
set -o pipefail

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 FILE1.mrg [FILE2.mrg [...]]" >&2
    exit 1
fi

for f in "$@"; do
    # Check that the argument is a .mrg format file
    if [ $(egrep -vc '^[[:space:]]*([()]|$)' "$f") -ne 0 ]; then
	echo "Warning: $f does not look like a .mrg file" >&2
    fi
    # Add CoNLL'03-style document separator
    echo $'-DOCSTART-\tO'
    # Conversion:
    # 1) map (NNP Pierre) -> Pierre/NNP
    # 2) map ( (S -> -SENTSTART-
    # 3) remove all (X and )
    # 4) max one word per line
    # 5) remove empty lines
    # 6) remove all */-NONE-
    # 7) map -SENTSTART- -> empty line
    # 8) map word/POS -> word<TAB>POS
    # 9-) unescape -LRB- -> ( etc.
    cat "$f" | \
	perl -pe 's/\(([^()\s]+)\s+([^()\s+]+)\)/$2\/$1/g' | \
	perl -pe 's/^\(\s+\(S\b(?:-\S+)?/-SENTSTART-/g' | \
	perl -pe 's/\(\S*//g; s/\)//g' | \
	tr ' ' '\n' | \
	egrep -v '^[[:space:]]*$' | \
	egrep -v '\/-NONE-$' | \
	perl -pe 's/-SENTSTART-//' |\
	perl -pe 's/(.*)\/(.*)$/$1\t$2/' |\
	perl -pe 's/-LRB-/(/g; s/-RRB-/)/g' |\
	perl -pe 's/-LSB-/[/g; s/-RSB-/]/g' |\
	perl -pe 's/-LCB-/{/g; s/-RCB-/}/g'
    echo
done
