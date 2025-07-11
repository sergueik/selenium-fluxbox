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
import platform
import sys
import textwrap
import urllib.error
import urllib.request
import zipfile
from pathlib import Path
from pprint import pprint
FEED_URL = (
    'https://googlechromelabs.github.io/chrome-for-testing/' + 'last-known-good-versions-with-downloads.json'
)
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
    p.add_argument("--version", help="full or major version (e.g. 137 or 137.0.6633.15)")
    p.add_argument(
        "--latest", action="store_true", help="ignore --version and fetch most recent"
    )
    p.add_argument(
        "--platform",
        default=detect_default_platform(),
        help="cft platform key (win64, linux64, mac-arm64, …). Default: auto-detect.",
    )
    p.add_argument("--download", action="store_true", help="download & unzip locally")
    p.add_argument("--out-dir", default="browsers", help="where to unzip if --download")
    return p.parse_args()

# NOTE: unsupported operand type(s) for |: 'type' and 'NoneType'
def choose_cft_entry(feed: dict, version: str, want_latest: bool):
    versions = feed["versions"]

    if want_latest or version is None:
        # choose newest by semantic version
        entry = max(versions, key=lambda v: tuple(int(x) for x in v["version"].split(".")))
        return entry

    # version argument supplied
    if "." not in version:  # major only
        major = version
        matches = [v for v in versions if v["version"].split(".")[0] == major]
        if not matches:
            return None
        return max(matches, key=lambda v: tuple(int(x) for x in v["version"].split(".")))
    else:  # exact string match
        for v in versions:
            if v["version"] == version:
                return v
        return None


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
    feed = json.loads(http_get(FEED_URL))
    pprint(feed)
    # NOTE: KeyError: 'versions'
    if args.version is None:
       args.version = ''  
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
    if args.platform not in entry["downloads"]:
        sys.exit(f"[!] platform {args.platform} not in feed for version {entry['version']}")

    url = entry["downloads"][args.platform]["url"]
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
