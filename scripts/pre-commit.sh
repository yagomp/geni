#!/bin/bash
# Pre-commit hook: scan staged files for common secret patterns.
# Install via: bash scripts/install-hooks.sh

set -e

STAGED=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED" ]; then
  exit 0
fi

FOUND=0
for FILE in $STAGED; do
  # Skip this file itself
  [[ "$FILE" == "scripts/pre-commit.sh" ]] && continue

  CONTENT=$(git show ":$FILE" 2>/dev/null) || continue

  check() {
    echo "$CONTENT" | grep -qE -e "$1" && \
      echo "SECRET DETECTED in $FILE (pattern: $2)" && FOUND=1 || true
  }

  check 'AKIA[0-9A-Z]{16}' 'AWS Access Key'
  check 'sk-[a-zA-Z0-9]{32,}' 'Generic secret key'
  check 'ghp_[a-zA-Z0-9]{36}' 'GitHub personal token'
  check 'ghs_[a-zA-Z0-9]{36}' 'GitHub app token'
  check 'BEGIN RSA PRIVATE KEY|BEGIN EC PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY' 'Private key'
  check 'MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQ' 'App Store Connect p8 key'
done

if [ $FOUND -ne 0 ]; then
  echo ""
  echo "Commit blocked. Remove secrets before committing."
  echo "If this is a false positive, add an exception in scripts/pre-commit.sh."
  exit 1
fi

exit 0
