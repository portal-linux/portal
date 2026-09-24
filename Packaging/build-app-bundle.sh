#!/bin/bash
# builds PortalApp.app: a real macOS app bundle wrapping the SwiftPM PortalApp
# executable, signed with the virtualization entitlement, ready to drag into
# /Applications. usage: Packaging/build-app-bundle.sh [debug|release]
set -euo pipefail

CONFIG="${1:-release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

case "$CONFIG" in
  debug) PRODUCTS_DIR=".build/out/Products/Debug" ;;
  release) PRODUCTS_DIR=".build/out/Products/Release" ;;
  *) echo "unknown config: $CONFIG (expected debug or release)" >&2; exit 1 ;;
esac

swift build -c "$CONFIG"

APP_BUNDLE="$ROOT_DIR/.build/PortalApp.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"

cp "$PRODUCTS_DIR/PortalApp" "$APP_BUNDLE/Contents/MacOS/PortalApp"
cp "$ROOT_DIR/Packaging/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

codesign --force --deep --sign - --entitlements "$ROOT_DIR/portal.entitlements" "$APP_BUNDLE"

echo "built $APP_BUNDLE"
