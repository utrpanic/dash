#!/bin/sh
set -eu

REPOSITORY_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SECRETS_FILE=${DASH_SECRETS_FILE:-"$REPOSITORY_ROOT/.secrets.properties"}
TARGET=${1:-all}
CURRENT_TEMP_FILE=

cleanup() {
  if [ -n "$CURRENT_TEMP_FILE" ]; then
    rm -f "$CURRENT_TEMP_FILE"
  fi
}

trap cleanup EXIT HUP INT TERM
umask 077

case "$TARGET" in
  ios|android|all) ;;
  *)
    echo "Usage: $0 [ios|android|all]" >&2
    exit 64
    ;;
esac

read_property() {
  key=$1
  [ -f "$SECRETS_FILE" ] || return 1

  awk -v key="$key" '
    index($0, key "=") == 1 {
      value = substr($0, length(key) + 2)
      sub(/\r$/, "", value)
      print value
      found = 1
      exit
    }
    END {
      if (!found) exit 1
    }
  ' "$SECRETS_FILE"
}

resolve_secret() {
  key=$1
  value=$(printenv "$key" 2>/dev/null || true)
  if [ -z "$value" ]; then
    value=$(read_property "$key" 2>/dev/null || true)
  fi
  if [ -z "$value" ]; then
    echo "Missing $key. Set the environment variable or add it to $SECRETS_FILE." >&2
    exit 65
  fi

  case "$value" in
    *"
"*)
      echo "$key must be a single-line value." >&2
      exit 65
      ;;
  esac

  printf '%s' "$value"
}

write_ios_secrets() {
  service_key=$1
  output_file="$REPOSITORY_ROOT/app-ios/DashFeature/DashData/Generated/Secrets.swift"
  output_directory=$(dirname "$output_file")
  mkdir -p "$output_directory"

  escaped_service_key=$(printf '%s' "$service_key" | sed 's/\\/\\\\/g; s/"/\\"/g')
  CURRENT_TEMP_FILE=$(mktemp "$output_file.tmp.XXXXXX")
  {
    printf '%s\n' 'enum Secrets {'
    printf '  static let serviceKey = "%s"\n' "$escaped_service_key"
    printf '%s\n' '}'
  } > "$CURRENT_TEMP_FILE"
  mv "$CURRENT_TEMP_FILE" "$output_file"
  CURRENT_TEMP_FILE=
}

write_android_secrets() {
  service_key=$1
  maps_api_key=$2
  output_file="$REPOSITORY_ROOT/app-android/secrets.properties"

  CURRENT_TEMP_FILE=$(mktemp "$output_file.tmp.XXXXXX")
  {
    printf 'DATA_GO_KR_SERVICE_KEY=%s\n' "$service_key"
    printf 'GOOGLE_MAPS_API_KEY=%s\n' "$maps_api_key"
  } > "$CURRENT_TEMP_FILE"
  mv "$CURRENT_TEMP_FILE" "$output_file"
  CURRENT_TEMP_FILE=
}

case "$TARGET" in
  ios)
    data_go_kr_service_key=$(resolve_secret DATA_GO_KR_SERVICE_KEY)
    write_ios_secrets "$data_go_kr_service_key"
    ;;
  android)
    data_go_kr_service_key=$(resolve_secret DATA_GO_KR_SERVICE_KEY)
    google_maps_api_key=$(resolve_secret GOOGLE_MAPS_API_KEY)
    write_android_secrets "$data_go_kr_service_key" "$google_maps_api_key"
    ;;
  all)
    data_go_kr_service_key=$(resolve_secret DATA_GO_KR_SERVICE_KEY)
    google_maps_api_key=$(resolve_secret GOOGLE_MAPS_API_KEY)
    write_ios_secrets "$data_go_kr_service_key"
    write_android_secrets \
      "$data_go_kr_service_key" \
      "$google_maps_api_key"
    ;;
esac

echo "Generated $TARGET secret configuration."
