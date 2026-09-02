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

def choose_cft_url(feed: dict, version: str, platform: str) -> str :
    rows = feed['versions']

    if version is None:
        entry = max(
            rows,
            key=lambda v: tuple(int(x) for x in v['version'].split('.'))
        )
    elif '.' not in version:
        matches = [
            row for row in rows
            if row['version'].split('.')[0] == version
        ]
        if not matches:
            print('no matches')
            return None

        entry = max(
            matches,
            key=lambda v: tuple(int(x) for x in v['version'].split('.'))
        )
    else:
        entry = next(
            (row for row in rows if row['version'] == version),
            None
        )

    if not entry:
        print(f'no entry for version {version}')
        return None
    rows2 =  entry['downloads']['chromedriver']
    print('examine entry')
    pprint(rows2)
    url = next((row["url"] for row in rows2 if row.get('platform') == platform), None)

    #url = next(
    #    (
    #        row.get('url')
    #        for row in entry['downloads']['chromedriver']
    #        if row.get('platform') == platform
    #    ),
    #    None
    #)

    print(f'url {url} for version {version} platform {platform}')
    return url

def choose_cft_entry(feed: dict, version: str, want_latest: bool) -> dict:
    rows = feed['versions']

    if want_latest or version is None:
        # choose newest by semantic version
        entry = max(rows, key=lambda v: tuple(int(x) for x in v['version'].split('.')))
        return entry

    # version argument supplied
    if '.' not in version:  # major only
        version_major = version
        matches = [row for row in rows if row['version'].split('.')[0] == version_major]
        if not matches:
            return None
        return max(matches, key=lambda v: tuple(int(x) for x in v['version'].split('.')))
    else:  # exact string match
        for row in rows:
            if row['version'] == version:
                return row
        return None

def choose_latest_version_url(feed: dict, platform: str) -> str:
    rows = feed['channels']['Stable']['downloads']['chromedriver']
    pprint(rows)

    platform_exists = any(row.get('platform') == platform for row in rows)

    if not platform_exists:
        sys.exit(f"[!] platform {platform} not in latest")

    url = next((row['url'] for row in rows if row.get('platform') == platform), None)
    print(f'latest url: {url}')
    return url

def choose_latest_version(feed: dict, platform: str)-> int:
    number = -1
    match = re.search(r'/(\d+)\.', choose_latest_version_url(feed, platform))

    if match:
        number = match.group(1)
        print(f'latest version: {number}')
        return number

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
    pprint(feed_url)
    feed = json.loads(http_get(feed_url))
    if args.version is None:
       args.version = ''
    if args.latest:
      print(f'args.platform={args.platform}')
      url = choose_latest_version_url(feed, args.platform)
    else:
      url = choose_cft_url(feed, args.version, args.platform)

    print(f'url={url}')
    if args.download is None:
        pass
    else:
        if args.version == '':
            match = re.search(r'/(\d+)\.', url)

            if match:
                number = match.group(1)
                print(f'version: {number}')
        else:
            number = args.version

        out_dir = Path(args.out_dir) / number
        out_dir.mkdir(parents=True, exist_ok=True)
        zip_path = out_dir / Path(url).name
        print(f'↳ downloading {url} …')
        urllib.request.urlretrieve(url, zip_path)
        print('↳ extracting …')
        unzip(zip_path, out_dir)

if __name__ == '__main__':
    main()
