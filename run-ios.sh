#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$PROJECT_DIR/EventReader.xcodeproj"
SCHEME="EventReader"
CONFIGURATION="Debug"
DERIVED_DATA="$PROJECT_DIR/DerivedData"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/EventReader.app"
BUNDLE_ID="com.chris.EventReader"
DEVICE_NAME="${DEVICE_NAME:-iPhone 17 Pro}"

echo "Building $SCHEME..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$DERIVED_DATA" \
  build

booted_device="$(xcrun simctl list devices booted | sed -n 's/.*(\([0-9A-F-]\{36\}\)) (Booted).*/\1/p' | head -n 1)"

if [[ -n "$booted_device" ]]; then
  device="$booted_device"
  echo "Using booted simulator: $device"
else
  device="$(xcrun simctl list devices available | sed -n "s/^[[:space:]]*$DEVICE_NAME (\([0-9A-F-]\{36\}\)) .*/\1/p" | head -n 1)"

  if [[ -z "$device" ]]; then
    echo "No available simulator named '$DEVICE_NAME'." >&2
    echo "Run 'xcrun simctl list devices available' and set DEVICE_NAME, for example:" >&2
    echo "DEVICE_NAME='iPhone 17' ./run-ios.sh" >&2
    exit 1
  fi

  echo "Booting simulator '$DEVICE_NAME': $device"
  xcrun simctl boot "$device"
  xcrun simctl bootstatus "$device" -b
fi

echo "Installing app..."
xcrun simctl install "$device" "$APP_PATH"

echo "Launching $BUNDLE_ID..."
xcrun simctl launch "$device" "$BUNDLE_ID"

open -a Simulator
