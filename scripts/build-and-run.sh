#!/bin/bash

# MiddleClick - Build and Run Script
# Builds the project in Debug mode and runs it without opening Xcode

set -e  # Exit on error

# Build only if BUILD_SKIP is not set (allows Makefile to skip redundant builds)
if [ -z "$BUILD_SKIP" ]; then
  echo "🔨 Building MiddleClick (Debug)..."
  xcodebuild -project MiddleClick.xcodeproj \
    -scheme MiddleClick \
    -configuration Debug \
    build \
    | grep -E "BUILD (SUCCEEDED|FAILED)|error:" || true

  # Check if build succeeded
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
  fi
  echo "✅ Build succeeded!"
fi

# Kill any existing MiddleClick instance
echo "🔄 Stopping any running MiddleClick instances..."
pkill -x MiddleClick 2>/dev/null || true
sleep 0.5

# Run the newly built app
echo "🚀 Starting MiddleClick..."

# Try to find the build directory dynamically if it doesn't exist
if [ ! -d "$BUILD_PATH" ]; then
  echo "🔍 Searching for build output..."
  BUILD_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "MiddleClick.app" -path "*/Build/Products/Debug/*" 2>/dev/null | xargs ls -td 2>/dev/null | head -1)
fi

# Check if the build was cleared by Xcode (contains Index.noindex)
if [[ "$BUILD_PATH" == *"/Index.noindex/"* ]]; then
  echo "⚠️  Detected cleared Xcode build, forcing rebuild..."
  exec make clean-build

  # If called by make, re-run to trigger rebuild
  if [ -n "$BUILD_SKIP" ]; then
    echo "🔄 Re-running make to rebuild..."
    exec make run
  fi
fi

if [ -d "$BUILD_PATH" ]; then
  open "$BUILD_PATH"
  echo "✨ MiddleClick is running!"
else
  echo "❌ Error: Could not find MiddleClick.app in build directory"
  exit 1
fi
