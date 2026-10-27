#!/bin/zsh
# One Geni build at a time on this Mac (a 16 GB machine crashed with ~10 parallel xcodebuilds).
# Usage: scripts/geni-build.sh            -> build-for-testing (compile check)
#        scripts/geni-build.sh app        -> Debug app build for the simulator
#        scripts/geni-build.sh archive     -> Release archive at /tmp/geni-release/Geni.xcarchive + App Store .ipa
#        scripts/geni-build.sh test [Only] -> unit tests on the one shared simulator, serially
#                                            (Only e.g. GeniTests/AgeFourTests)
#        scripts/geni-build.sh test-run <xctestrun> [Only] -> run a prepared capture/test configuration
# Waits for any other Geni build to finish, uses one shared DerivedData and 4 compile jobs.
set -u
lock=/tmp/geni-build.lock
until mkdir "$lock" 2>/dev/null; do
  if [[ -f "$lock/pid" ]] && ! kill -0 "$(cat "$lock/pid")" 2>/dev/null; then rm -rf "$lock"; continue; fi
  sleep 15
done
echo $$ > "$lock/pid"
trap 'rm -rf "$lock"' EXIT
cd "${0:A:h}/../ios"
action=(build-for-testing)
destination='generic/platform=iOS Simulator'
[[ "${1:-}" == app ]] && action=(build -configuration Debug)
if [[ "${1:-}" == test ]]; then
  # The single shared simulator; never let Xcode clone it for parallel testing.
  destination='id=B0B5D7B2-D70D-4621-8B4A-23A0F1E03067'
  action=(test -parallel-testing-enabled NO -only-testing:"${2:-GeniTests}")
fi
if [[ "${1:-}" == test-run ]]; then
  [[ -f "${2:-}" ]] || { echo 'Usage: scripts/geni-build.sh test-run <absolute xctestrun path> [Only]'; exit 2; }
  xcodebuild test-without-building -xctestrun "$2" \
    -destination 'id=B0B5D7B2-D70D-4621-8B4A-23A0F1E03067' \
    -derivedDataPath "${GENI_DD:-/tmp/geni-dd}" -jobs 4 -parallel-testing-enabled NO \
    -only-testing:"${3:-GeniTests}" > /tmp/geni-build.log 2>&1
  rc=$?
  grep -E ' error:|failed|TEST EXECUTE (SUCCEEDED|FAILED)' /tmp/geni-build.log | tail -20
  exit $rc
fi
if [[ "${1:-}" == archive ]]; then
  out=/tmp/geni-release; rm -rf "$out"; mkdir -p "$out"
  cat > "$out/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>ZBRDR5Q455</string>
  <key>signingStyle</key><string>manual</string>
  <key>provisioningProfiles</key><dict><key>com.yagomp.geni</key><string>Geni AppStore Release</string></dict>
  <key>uploadSymbols</key><true/>
  <key>destination</key><string>export</string>
</dict></plist>
PLIST
  xcodebuild archive -project Geni.xcodeproj -scheme Geni -configuration Release \
    -destination 'generic/platform=iOS' -archivePath "$out/Geni.xcarchive" \
    -derivedDataPath "${GENI_DD:-/tmp/geni-dd}-release" -jobs 4 > /tmp/geni-build.log 2>&1 &&
  xcodebuild -exportArchive -archivePath "$out/Geni.xcarchive" -exportPath "$out" \
    -exportOptionsPlist "$out/ExportOptions.plist" >> /tmp/geni-build.log 2>&1
  rc=$?
  grep -E " error:|ARCHIVE (SUCCEEDED|FAILED)|EXPORT (SUCCEEDED|FAILED)" /tmp/geni-build.log | sort -u | head -20
  ls "$out"/*.ipa 2>/dev/null
  exit $rc
fi
xcodebuild "${action[@]}" -project Geni.xcodeproj -scheme Geni -sdk iphonesimulator \
  -destination "$destination" -derivedDataPath "${GENI_DD:-/tmp/geni-dd}" \
  -jobs 4 CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES > /tmp/geni-build.log 2>&1
rc=$?
grep -E " error:|✘ Test|recorded an issue" /tmp/geni-build.log | sort -u | head -40
grep -E "(TEST )?BUILD (SUCCEEDED|FAILED)" /tmp/geni-build.log | tail -1
exit $rc
