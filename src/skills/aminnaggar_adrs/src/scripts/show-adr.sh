#!/bin/bash
# Show full ADR content
# Usage: show-adr.sh <id> [-p path]
#
# Examples:
#   show-adr.sh 003
#   show-adr.sh ADR-003
#   show-adr.sh 003 -p ../other

source "$(dirname "$0")/_common.sh"
parse_flags "$@"
shift $SHIFT_COUNT
require_adr_dir

RAW_ID="$1"

if [ -z "$RAW_ID" ]; then
    echo "Usage: show-adr.sh <id> [-p path]" >&2
    exit 1
fi

ADR_FILE=$(resolve_adr_file "$RAW_ID")

if [ -z "$ADR_FILE" ] || [ ! -f "$ADR_FILE" ]; then
    echo "Error: ADR not found: $RAW_ID" >&2
    echo "" >&2
    echo "Run list-adrs.sh to see available ADRs." >&2
    exit 1
fi

cat "$ADR_FILE"
