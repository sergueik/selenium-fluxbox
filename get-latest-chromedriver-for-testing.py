#!/usr/bin/env python3
"""
get-latest-chromedriver-for-testing.py


Examines Chrome‑for‑Testing* feed and prints the
Chrome + ChromeDriver download URL that matches a requested major version and operating system.

Usage
─────
# get the most recentb stable version for operarting system the script is run
python get-latest-chromedriver-for-testing.py --latest

# get specific milestone & platform
python get-latest-chromedriver-for-testing.py --version 131 --platform win64

# full version match
python get-latest-chromedriver-for-testing.py --version 131.0.6533.32 --platform linux64

# default is to return the driver download url.  
# use --download option to fetch and unzip the driver to the script directory.

"""
import argparse
import json
import os
import re
import platform
import sys
import textwrap
import urllib.error
import urllib.request
import zipfile
from pathlib import Path
from pprint import pprint
# FEED_URL = (
#    'https://googlechromelabs.github.io/chrome-for-testing/' + 'last-known-good-versions-with-downloads.json'
# )
# from https://github.com/GoogleChromeLabs/chrome-for-testing?tab=readme-ov-file#json-api-endpoints

FEED_URL = 'https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json'
LASTGOOD_VERSION_URL = 'https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json'
KNOWN_VERSIONS_URL = 'https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json'

LEGACY_BASE = 'https://chromedriver.storage.googleapis.com'  # for < M115 fallback


def detect_default_platform() -> str:
    """Maps the running OS/arch to a CFT platform key."""
    # NOTE: when unable to determine, assumes 64-bit linux 
    # See Also: https://stackoverflow.com/questions/8220108/how-do-i-check-the-operating-system-in-python - sys.platform is less accurate 
    sys_map = {
        ("Windows", "AMD64"): "win64",
        ("Windows", "x86_64"): "win64",
        ("Windows", "x86"): "win32",
        ("Linux", "x86_64"): "linux64",
        ("Linux", "aarch64"): "linux64",
        ("Darwin", "x86_64"): "mac-x64",
        ("Darwin", "arm64"): "mac-arm64",
    }
    key = ( platform.system(), platform.machine() )
    # TODO: handle the platform.version() or sys.getwindowsversion().majorm
    return sys_map.get(key, "linux64")


def http_get(url: str) -> str:
    with urllib.request.urlopen(url, timeout=15) as resp:
        charset = resp.headers.get_content_charset() or "utf-8"
        return resp.read().decode(charset)


def resolve_legacy_version(major: str) -> str:
    """Return the exact legacy ChromeDriver version for a given major."""
    try:
        url = f"{LEGACY_BASE}/LATEST_RELEASE_{major}"
        return http_get(url).strip()
    except urllib.error.HTTPError:
        raise SystemExit(f"[!] Could not resolve legacy ChromeDriver for major {major}")


def unzip(zip_path: Path, dest: Path) -> None:
    with zipfile.ZipFile(zip_path) as zf:
        zf.extractall(dest)


def parse_args():
    p = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=textwrap.dedent(
            """
            Query the Chrome‑for‑Testing feed and print (or download) the matching
            Chrome/ChromeDriver build.
            """
        ),
    )
    p.add_argument('--version', help='full or major version (e.g. 137 or 137.0.6633.15)')
    p.add_argument(
        '--latest', action='store_true', help='ignore --version and fetch most recent'
    )
    p.add_argument(
        '--platform',
        default=detect_default_platform(),
        help='cft platform key (win64, linux64, mac-arm64, …). Default: auto-detect.',
    )
    p.add_argument('--download', action='store_true', help='download & unzip locally')
    p.add_argument('--out-dir', default='browsers', help='where to unzip if --download')
    return p.parse_args()

# NOTE: unsupported operand type(s) for |: 'type' and 'NoneType'
def choose_cft_entry(feed: dict, version: str, want_latest: bool):
    versions = feed['versions']

    if want_latest or version is None:
        # choose newest by semantic version
        entry = max(versions, key=lambda v: tuple(int(x) for x in v['version'].split('.')))
        return entry

    # version argument supplied
    if '.' not in version:  # major only
        major = version
        matches = [v for v in versions if v['version'].split('.')[0] == major]
        if not matches:
            return None
        return max(matches, key=lambda v: tuple(int(x) for x in v['version'].split('.')))
    else:  # exact string match
        for v in versions:
            if v['version'] == version:
                return v
        return None

def choose_latest(feed: dict, platform: str):
    versions = feed['channels']['Stable']['downloads']['chromedriver']
    pprint(versions)
    # [{'platform': 'linux64', 'url': 'https://storage.googleapis.com/chrome-for-testing-public/152.0.7977.75/linux64/chromedriver-linux64.zip'}
 
    platform_exists = any(row.get('platform') == platform for row in versions)

    if not platform_exists:
        sys.exit(f"[!] platform {platform} not in latest")

    url = next((row["url"] for row in versions if row.get('platform') == platform), None)
    print(f'latest url: {url}')
    
    match = re.search(r'/(\d+)\.', url)

    if match:
        number = match.group(1)
        print(f'latest version: {number}')

def build_legacy_url(version: str, platform: str) -> str:
    plat_map = {
        'win64': 'chromedriver_win32.zip',
        'win32': 'chromedriver_win32.zip',
        'linux64': 'chromedriver_linux64.zip',
        'mac-x64': 'chromedriver_mac64.zip',
        'mac-arm64': 'chromedriver_mac64_m1.zip',
    }
    return f'{LEGACY_BASE}/{version}/{plat_map[platform]}'


def main():
    args = parse_args()

    # fetch feed once
    if args.latest:
       feed_url = LASTGOOD_VERSION_URL
    else:
       feed_url = KNOWN_VERSIONS_URL
    feed = json.loads(http_get(feed_url))
    pprint(feed_url)
    # TODO: debug option
    # pprint(feed)
    # NOTE: KeyError: 'versions'
    if args.version is None:
       args.version = ''  
    if args.latest:
      version = choose_latest(feed, args.platform)
      feed_url = KNOWN_VERSIONS_URL
      feed = json.loads(http_get(feed_url))
      entry = choose_cft_entry(feed, version, args.latest)
    # the existing code logic does not look promising
    else:
      entry = choose_cft_entry(feed, args.version, args.latest)

    if not entry:
        # maybe legacy (pre‑115) requested
        if args.version is None:
            sys.exit('[!] --version required when querying legacy pre-115 builds')
        legacy_ver = resolve_legacy_version(args.version)
        url = build_legacy_url(legacy_ver, args.platform)
        print(url)
        if args.download:
            out_dir = Path(args.out_dir) / legacy_ver
            out_dir.mkdir(parents=True, exist_ok=True)
            zip_path = out_dir / Path(url).name
            print(f"↳ downloading {url} …")
            urllib.request.urlretrieve(url, zip_path)
            print("↳ extracting …")
            unzip(zip_path, out_dir)
        return

    # Found CFT entry
    pprint( entry['downloads']['chromedriver'])
    # [
    # {'platform': 'linux64', 'url': 'https://storage.googleapis.com/chrome-for-testing-public/129.0.6668.100/linux64/chrome-linux64.zip'},
    # {'platform': 'mac-arm64', 'url': 'https://storage.googleapis.com/chrome-for-testing-public/129.0.6668.100/mac-arm64/chrome-mac-arm64.zip'},
    # {'platform': 'mac-x64', 'url': 'https://storage.googleapis.com/chrome-for-testing-public/129.0.6668.100/mac-x64/chrome-mac-x64.zip'},
    # {'platform': 'win32', 'url': 'https://storage.googleapis.com/chrome-for-testing-public/129.0.6668.100/win32/chrome-win32.zip'},
    # {'platform': 'win64', 'url': 'https://storage.googleapis.com/chrome-for-testing-public/129.0.6668.100/win64/chrome-win64.zip'}
    # ]

    platform_exists = any(row.get('platform') == args.platform for row in entry['downloads']['chromedriver'])

    if not platform_exists:
        sys.exit(f"[!] platform {args.platform} not in feed for version {entry['version']}")

    url = next((row["url"] for row in entry['downloads']['chromedriver'] if row.get('platform') == args.platform), None)
    print(url)

    if args.download:
        out_dir = Path(args.out_dir) / entry["version"]
        out_dir.mkdir(parents=True, exist_ok=True)
        zip_path = out_dir / Path(url).name
        print(f"↳ downloading {url} …")
        urllib.request.urlretrieve(url, zip_path)
        print("↳ extracting …")
        unzip(zip_path, out_dir)

if __name__ == "__main__":
    main()
