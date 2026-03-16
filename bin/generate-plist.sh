#!/bin/bash
# Generates launchd plist with user-specific home directory
#
# Usage: generate-plist.sh
#
# Generates ~/Library/LaunchAgents/com.llama-swap.plist from the template
# with ${HOME} replaced by the user's actual home directory path.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE="$REPO_DIR/Library/LaunchAgents/com.llama-swap.plist.tmpl"
OUTPUT_DIR="$HOME/Library/LaunchAgents"
OUTPUT="$OUTPUT_DIR/com.llama-swap.plist"

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	echo "Usage: $0"
	echo ""
	echo "Generates launchd plist with user-specific home directory."
	echo "Output: ~/Library/LaunchAgents/com.llama-swap.plist"
	exit 0
fi

if [[ ! -f "$TEMPLATE" ]]; then
	echo "Error: Template not found at $TEMPLATE"
	exit 1
fi

mkdir -p "$OUTPUT_DIR"

HOME_ESCAPED=$(echo "$HOME" | sed 's/\//\\\//g')
sed "s/\\\${HOME}/$HOME_ESCAPED/g" "$TEMPLATE" >"$OUTPUT"

echo "Generated: $OUTPUT"
echo "To load: launchctl load $OUTPUT"
