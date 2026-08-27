#!/usr/bin/env bash
# Bumps the MiddleClick version following Semantic Versioning (semver.org).
#
# Usage: scripts/bump-version.sh <major|minor|patch>
#
# - patch: backwards-compatible bug fixes        e.g. 3.2.0 → 3.2.1
# - minor: new backwards-compatible features     e.g. 3.2.1 → 3.3.0
# - major: breaking / incompatible changes       e.g. 3.3.0 → 4.0.0
#
# All version components are treated as integers so comparisons and
# increments are always correct (e.g. 3.9 → 3.10, never 3.9 → 3.91).
#
# Run from the repository root.

set -euo pipefail

USAGE="Usage: $0 <major|minor|patch>"
BUMP=${1:-}

if [[ -z "$BUMP" ]]; then
  echo "$USAGE" >&2
  exit 1
fi

case "$BUMP" in
  major|minor|patch) ;;
  *)
    echo "Error: argument must be 'major', 'minor', or 'patch'" >&2
    echo "$USAGE" >&2
    exit 1
    ;;
esac

XCODEPROJ="MiddleClick.xcodeproj/project.pbxproj"
CHANGELOG="docs/CHANGELOG.md"

if [[ ! -f "$XCODEPROJ" ]]; then
  echo "Error: $XCODEPROJ not found. Run this script from the repository root." >&2
  exit 1
fi

# Read current versions from the first occurrence of each field.
# Using grep -m1 handles the fact that both Debug and Release configs repeat
# these keys — we verify they are in sync before writing.
CURRENT_MARKETING=$(grep -m1 'MARKETING_VERSION' "$XCODEPROJ" | sed 's/.*= //;s/;//;s/ //g')
CURRENT_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION' "$XCODEPROJ" | sed 's/.*= //;s/;//;s/ //g')

# Verify all copies of each field agree (Debug and Release configs must match).
MARKETING_COUNT=$(grep -c "MARKETING_VERSION = ${CURRENT_MARKETING};" "$XCODEPROJ" || true)
BUILD_COUNT=$(grep -c "CURRENT_PROJECT_VERSION = ${CURRENT_BUILD};" "$XCODEPROJ" || true)
TOTAL_MARKETING=$(grep -c 'MARKETING_VERSION' "$XCODEPROJ" || true)
TOTAL_BUILD=$(grep -c 'CURRENT_PROJECT_VERSION' "$XCODEPROJ" || true)

if [[ "$MARKETING_COUNT" != "$TOTAL_MARKETING" || "$BUILD_COUNT" != "$TOTAL_BUILD" ]]; then
  echo "Error: version fields are inconsistent across build configurations in $XCODEPROJ." >&2
  echo "  MARKETING_VERSION: $MARKETING_COUNT/$TOTAL_MARKETING copies match '$CURRENT_MARKETING'" >&2
  echo "  CURRENT_PROJECT_VERSION: $BUILD_COUNT/$TOTAL_BUILD copies match '$CURRENT_BUILD'" >&2
  echo "Fix manually before running this script." >&2
  exit 1
fi

# Split MARKETING_VERSION into integer components.
# Using integer variables throughout prevents any risk of lexicographic
# comparison bugs (e.g. "10" < "9" as strings).
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_MARKETING"

if ! [[ "${MAJOR:-}" =~ ^[0-9]+$ && "${MINOR:-}" =~ ^[0-9]+$ && "${PATCH:-}" =~ ^[0-9]+$ ]]; then
  echo "Error: MARKETING_VERSION '$CURRENT_MARKETING' is not in MAJOR.MINOR.PATCH integer format." >&2
  exit 1
fi

# Increment the chosen component; reset subordinate components to zero.
case "$BUMP" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
esac

NEW_MARKETING="${MAJOR}.${MINOR}.${PATCH}"
NEW_BUILD=$((CURRENT_BUILD + 1))

echo "Bumping version ($BUMP):"
echo "  Marketing: $CURRENT_MARKETING → $NEW_MARKETING"
echo "  Build:     $CURRENT_BUILD → $NEW_BUILD"

# Update all occurrences of each field in the xcodeproj.
sed -i '' \
  "s/MARKETING_VERSION = ${CURRENT_MARKETING};/MARKETING_VERSION = ${NEW_MARKETING};/g" \
  "$XCODEPROJ"
sed -i '' \
  "s/CURRENT_PROJECT_VERSION = ${CURRENT_BUILD};/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" \
  "$XCODEPROJ"

# Stamp docs/CHANGELOG.md: replace the [Unreleased] header with a versioned
# entry and insert a fresh empty [Unreleased] section above it for future work.
TODAY=$(date +%Y-%m-%d)

python3 - <<PYEOF
import sys

changelog_path = '$CHANGELOG'
new_version    = '$NEW_MARKETING'
today          = '$TODAY'

unreleased_marker = '## [Unreleased]'
versioned_header  = f'## [{new_version}] - {today}'

try:
    text = open(changelog_path).read()
except FileNotFoundError:
    print(f"Warning: {changelog_path} not found — skipping changelog stamp.", file=sys.stderr)
    sys.exit(0)

if unreleased_marker not in text:
    print(f"Warning: '{unreleased_marker}' not found in {changelog_path} — skipping changelog stamp.", file=sys.stderr)
    sys.exit(0)

# Place a fresh [Unreleased] section before the now-versioned entry.
text = text.replace(
    unreleased_marker,
    f'{unreleased_marker}\n\n---\n\n{versioned_header}',
    1,
)
open(changelog_path, 'w').write(text)
print(f'  Changelog: [Unreleased] → [{new_version}] - {today}')
PYEOF

echo "✅ Done. Review changes with: git diff"
echo "   Next step: follow docs/maintain.md to create a draft release."
