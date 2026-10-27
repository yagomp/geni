#!/usr/bin/env python3
"""Fingerprint the site's shared CSS/JS so browsers never mix a new page with an old stylesheet.

Cloudflare tells browsers to cache .css/.js for hours, while HTML always revalidates.
Every reference to a shared asset gets ?v=<content hash>, so a changed file gets a new URL.
Run before publishing: python3 scripts/site-assets.py [path/to/site]
"""
import hashlib
import pathlib
import re
import sys

SITE = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else pathlib.Path(__file__).resolve().parent.parent / "site"
ASSETS = ["geni.css", "nav.js", "footer.js", "phone-demo.js", "hero-demo.js"]

versions = {
    name: hashlib.sha256((SITE / name).read_bytes()).hexdigest()[:10]
    for name in ASSETS
}

changed = []
for page in sorted(SITE.rglob("*.html")):
    html = page.read_text(encoding="utf-8")
    out = html
    for name, version in versions.items():
        pattern = r'((?:src|href)="(?:\.\./)?' + re.escape(name) + r')(?:\?v=[^"]*)?"'
        out = re.sub(pattern, r'\1?v=' + version + '"', out)
    if out != html:
        page.write_text(out, encoding="utf-8")
        changed.append(str(page.relative_to(SITE)))

for name, version in versions.items():
    print(f"{name:15} {version}")
print(f"updated {len(changed)} page(s)" + (": " + ", ".join(changed) if changed else ""))
