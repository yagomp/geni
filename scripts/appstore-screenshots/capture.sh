#!/bin/bash
# No build, boot, installation, device creation, or simulator-wide locale changes.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLAN="$ROOT/scripts/appstore-screenshots/plan.json"
DEVICE=iphone
LANGUAGES=en,no
VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$PLAN")"
RAW_ROOT="$ROOT/screenshots/v$VERSION/raw"
WAIT_SECONDS=2
DRY_RUN=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    iphone|ipad) DEVICE="$1"; shift ;;
    --device) DEVICE="$2"; shift 2 ;;
    --languages) LANGUAGES="$2"; shift 2 ;;
    --raw-root) RAW_ROOT="$2"; shift 2 ;;
    --wait) WAIT_SECONDS="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
case "$DEVICE" in
  iphone|iphone-6.7) DEVICE=iphone-6.7; UDID=B0B5D7B2-D70D-4621-8B4A-23A0F1E03067 ;;
  ipad|ipad-12.9) DEVICE=ipad-12.9; UDID=EE0FE5EC-BB55-4D35-AB76-A04D3A10A50C ;;
  *) echo 'Device must be iphone or ipad' >&2; exit 2 ;;
esac
# Planning never contacts CoreSimulator. Use this while another project owns the device.
ROWS="$(python3 - "$PLAN" "$LANGUAGES" <<'PY'
import json,sys
p=json.load(open(sys.argv[1]))
for lang in sys.argv[2].split(','):
    l=p['languages'][lang]
    screens={screen:shot.get('previewAge',7) for shot in p['shots'] for screen in shot['screens']}
    for screen,age in screens.items():
        print('\t'.join([lang,screen,l['appLanguage'],l['appleLanguage'],l['appleLocale'],str(age),l['storeRegion']]))
PY
)"
if $DRY_RUN; then
  printf 'Device: %s (%s)\nRaw root: %s\n%s\n' "$UDID" "$DEVICE" "$RAW_ROOT" "$ROWS"
  exit 0
fi
# Refuse to boot somebody else's simulator or accidentally target a different device.
xcrun simctl list devices --json | python3 -c 'import json,sys; ds=[d for a in json.load(sys.stdin)["devices"].values() for d in a if d["udid"]==sys.argv[1]]; assert len(ds)==1 and ds[0]["state"]=="Booted", "Requested simulator must already be booted by its owner"' "$UDID"
APP_PATH="$(xcrun simctl get_app_container "$UDID" com.yagomp.geni app)"
[[ -d "$APP_PATH" ]] || { echo 'Install the DEBUG app first' >&2; exit 1; }
cleanup() { xcrun simctl status_bar "$UDID" clear; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
# Invalidate receipts before starting, so an interrupted capture cannot be composed/uploaded.
IFS=',' read -ra LANG_ARRAY <<< "$LANGUAGES"
for lang in "${LANG_ARRAY[@]}"; do
  mkdir -p "$RAW_ROOT/$DEVICE/$lang"
  rm -f "$RAW_ROOT/$DEVICE/$lang/.capture.json"
done
while IFS=$'\t' read -r lang screen app_language apple_language apple_locale age store_region; do
  xcrun simctl launch --terminate-running-process "$UDID" com.yagomp.geni \
    -uiTestReset -designPreview "$screen" -designPreviewAge "$age" -designPreviewStore -geniStoreRegion "$store_region" \
    -geni_app_language "$app_language" -AppleLanguages "($apple_language)" -AppleLocale "$apple_locale" -AppleInterfaceStyle Light
  sleep "$WAIT_SECONDS"
  xcrun simctl io "$UDID" screenshot "$RAW_ROOT/$DEVICE/$lang/$screen.png"
done <<< "$ROWS"
python3 - "$PLAN" "$RAW_ROOT/$DEVICE" "$LANGUAGES" "$DEVICE" "$UDID" <<'PY'
import datetime,hashlib,json,struct,sys
from pathlib import Path
p=json.load(open(sys.argv[1])); root=Path(sys.argv[2])
for lang in sys.argv[3].split(','):
    screens=list(dict.fromkeys(s for shot in p['shots'] for s in shot['screens']))
    files={}
    for screen in screens:
        data=(root/lang/(screen+'.png')).read_bytes()
        w,h=struct.unpack('>II',data[16:24])
        expected=[(1206,2622)] if sys.argv[4]=='iphone-6.7' else [(2064,2752),(2048,2732)]
        assert (w,h) in expected, f'{screen}: wrong dimensions {w}x{h}; expected {expected}'
        files[screen]=hashlib.sha256(data).hexdigest()
    receipt={'version':p['version'],'language':lang,'udid':sys.argv[5],'capturedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sha256':files}
    (root/lang/'.capture.json').write_text(json.dumps(receipt,indent=2)+'\n')
PY
