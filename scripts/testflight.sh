#!/bin/bash
# Archive, export, and upload to TestFlight with asc (App Store Connect CLI).
#
# Requires:
#   asc auth login (once, globally — same key for every app under the team)
#   ASC_APP_ID   App Store Connect app ID (numeric), or pass as $1
#
# The Xcode project is committed as JSON (App/TabiMemo.xcodeproj/project.xcproj, Xcode 27+), so there is no generate step.
#
# Usage: scripts/testflight.sh APP_ID [--group "Internal"] [--notify]
set -euo pipefail
cd "$(dirname "$0")/.."

APP_ID="${ASC_APP_ID:-}"
if [[ $# -gt 0 && "$1" != --* ]]; then
  APP_ID="$1"
  shift
fi
if [[ -z "$APP_ID" ]]; then
  echo "usage: scripts/testflight.sh APP_ID [--group NAME]" >&2
  exit 1
fi

PROJECT=App/TabiMemo.xcodeproj
SCHEME=TabiMemo
VERSION=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -skipPackagePluginValidation -showBuildSettings 2>/dev/null \
  | awk -F' = ' '/ MARKETING_VERSION = /{print $2; exit}')

exec asc publish testflight \
  --app "$APP_ID" \
  --project "$PROJECT" \
  --scheme "$SCHEME" \
  --configuration Release \
  --version "$VERSION" \
  --export-options scripts/ExportOptions.plist \
  --archive-path "build/$SCHEME.xcarchive" \
  --ipa-path "build/$SCHEME.ipa" \
  --archive-xcodebuild-flag -allowProvisioningUpdates \
  --archive-xcodebuild-flag -skipPackagePluginValidation \
  --export-xcodebuild-flag -allowProvisioningUpdates \
  --wait \
  --pretty \
  "${@:---upload-only}"
