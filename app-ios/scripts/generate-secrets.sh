#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_FILE="$ROOT_DIR/DashFeature/DashFeature/Generated/Secrets.swift"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <DATA_GO_KR_SERVICE_KEY>" >&2
  exit 64
fi

SERVICE_KEY="$1"

mkdir -p "$(dirname "$OUTPUT_FILE")"

escaped_service_key=$(printf '%s' "$SERVICE_KEY" | sed 's/\\/\\\\/g; s/"/\\"/g')

cat > "$OUTPUT_FILE" <<EOF
enum GeneratedSecrets {
  static let dataGoKrServiceKey = "$escaped_service_key"
}
EOF
