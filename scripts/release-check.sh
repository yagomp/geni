#!/bin/zsh
# Release gate: run before every App Store upload. Fails on any test failure or on a reachable trap
# in exercise generation (the 1.2.0 spotlight crash came from a fatalError behind a format picker).
set -u
cd "${0:A:h}/.."
fail=0
if grep -nE "fatalError|preconditionFailure|try!" ios/Geni/Services/ExerciseGenerator.swift ios/Geni/Games -r; then
  echo "✘ Trap in exercise generation (above). Replace it with a safe fallback."; fail=1
fi
scripts/geni-build.sh test || fail=1
grep -E "Test run with" /tmp/geni-build.log | tail -1
[[ $fail == 0 ]] && echo "✔ Release check passed" || echo "✘ Release check FAILED — do not upload"
exit $fail
