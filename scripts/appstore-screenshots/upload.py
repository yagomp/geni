#!/usr/bin/env python3
"""Default: read-only ASC inventory. --dry-run plans replacement; --apply replaces only screenshots."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
PLAN = json.loads((Path(__file__).parent / 'plan.json').read_text())
AUDIT = json.loads((Path(__file__).parent / 'asc-coverage.json').read_text())


def asc(*args, readonly=True):
    command = ['asc'] + (['--read-only'] if readonly else []) + list(args) + ['--output', 'json']
    return json.loads(subprocess.check_output(command, text=True))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--list', action='store_true', help='Read current sets/IDs only (default)')
    mode.add_argument('--dry-run', action='store_true', help='Validate all files and plan deletions/uploads without writing ASC')
    mode.add_argument('--apply', action='store_true', help='Replace screenshot sets after all locale preflights pass')
    parser.add_argument('--root', type=Path, default=ROOT / 'screenshots/v1.2.0')
    parser.add_argument('--device', choices=['iphone', 'ipad', 'iphone-6.7', 'ipad-12.9'], default='iphone')
    args = parser.parse_args()
    args.device = {'iphone': 'iphone-6.7', 'ipad': 'ipad-12.9'}.get(args.device, args.device)
    display_type = 'APP_IPHONE_67' if args.device == 'iphone-6.7' else 'APP_IPAD_PRO_3GEN_129'
    cli_type = display_type.removeprefix('APP_')
    expected_dimensions = (1290, 2796) if args.device == 'iphone-6.7' else (2048, 2732)
    inventory = asc('screenshots', 'list', '--app', PLAN['appId'], '--version-id', PLAN['versionId'])
    locales = {l['locale']: l for l in inventory['localizations']}
    summary = [{'locale': l['locale'], 'localizationId': l['versionLocalizationId'], 'sets': [
        {'id': s['set']['id'], 'displayType': s['set']['attributes']['screenshotDisplayType'],
         'screenshots': [{'id': a['id'], 'name': a['attributes']['fileName']} for a in s['screenshots']]}
        for s in l['sets']]} for l in inventory['localizations']]
    if not (args.dry_run or args.apply):
        print(json.dumps(summary, indent=2))
        return
    # asc scans every directory entry, including JSON receipts. Stage only the ten PNGs.
    with tempfile.TemporaryDirectory(prefix='geni-store-upload-') as stage:
        replace_sets(args, inventory, cli_type, expected_dimensions, Path(stage))


def replace_sets(args, inventory, cli_type, expected_dimensions, staging):
    locales = {l['locale']: l for l in inventory['localizations']}
    version = asc('versions', 'view', '--version-id', PLAN['versionId'])
    assert version['id'] == PLAN['versionId'], 'Unexpected App Store version resource'
    assert version['versionString'] == '1.2.0', 'Version ID no longer matches 1.2.0'
    assert version['state'] == 'PREPARE_FOR_SUBMISSION', 'Version must remain editable, before submission'
    audited = {l['locale']: l for l in AUDIT['localizations']}
    uploads = []
    previews = []
    # Preflight EVERY locale before allowing any deletion. Samples cannot pass this gate.
    for lang, locale in PLAN['languages'].items():
        asc_locale = locale['ascLocale']
        current = locales[asc_locale]
        assert current['versionLocalizationId'] == audited[asc_locale]['id'], f'Unexpected localization ID for {asc_locale}'
        directory = args.root / args.device / lang
        receipt = json.loads((directory / '.composed.json').read_text())
        assert receipt['version'] == PLAN['version'] and receipt['language'] == lang and receipt['device'] == args.device, 'Wrong composition receipt'
        expected_names = {s['id'] + '.png' for s in PLAN['shots']}
        assert {p.name for p in directory.glob('*.png')} == expected_names, f'{directory}: expected exactly 01.png–10.png'
        assert set(receipt['sha256']) == expected_names, 'Incomplete composition receipt'
        for name in sorted(expected_names):
            data = (directory / name).read_bytes()
            assert data[:8] == b'\x89PNG\r\n\x1a\n', f'{name}: invalid PNG'
            assert struct.unpack('>II', data[16:24]) == expected_dimensions, f'{name}: wrong dimensions'
            assert data[25] == 2, f'{name}: PNG must be RGB without alpha'
            assert hashlib.sha256(data).hexdigest() == receipt['sha256'][name], f'{name}: changed since composition'
        staged = staging / lang
        staged.mkdir()
        for name in sorted(expected_names):
            os.link(directory / name, staged / name)
        command = ['screenshots', 'upload', '--version-localization', current['versionLocalizationId'],
                   '--path', str(staged), '--device-type', cli_type, '--replace']
        # ASC verifies accepted size, existing target set, and per-set count too.
        preview = asc(*command, '--dry-run')
        previews.append({'locale': asc_locale, 'plan': preview})
        uploads.append(command)
    results = []
    if args.apply:
        # Keep the pre-replacement inventory for recovery/audit. No version, build, metadata or submission mutations.
        report = ROOT / '.asc/reports/screenshots-1.2.0'
        report.mkdir(parents=True, exist_ok=True)
        (report / 'before.json').write_text(json.dumps(inventory, indent=2) + '\n')
        for command in uploads:
            results.append(asc(*command, '--confirm', readonly=False))
    print(json.dumps({'mode': 'apply' if args.apply else 'dry-run', 'previews': previews, 'uploads': results}, indent=2))


if __name__ == '__main__':
    try:
        main()
    except (AssertionError, KeyError, OSError, subprocess.CalledProcessError, ValueError) as error:
        sys.exit(f'Screenshot operation stopped: {error}')
