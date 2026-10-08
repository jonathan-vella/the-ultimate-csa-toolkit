"""Audit locked package versions; download routing remains on CFS."""

from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
import json
from pathlib import Path
import re
import sys
import tomllib
from urllib.parse import quote
from urllib.request import urlopen


ROOT = Path(__file__).resolve().parent


def metadata(url):
    with urlopen(url, timeout=60) as response:
        return json.load(response)


def check(task, cutoff):
    ecosystem, name, versions = task
    errors = []
    if ecosystem == "npm":
        data = metadata(
            f"https://packagefeedproxy.microsoft.io/npm/{quote(name, safe='')}"
        )
    else:
        # Replica ingestion timestamps are not original PyPI publication dates.
        data = metadata(f"https://pypi.org/pypi/{quote(name, safe='')}/json")
    for version in versions:
        label = f"{ecosystem}: {name}=={version}"
        stable = (
            r"\d+(?:\.\d+)+"
            if ecosystem == "npm"
            else r"\d+(?:\.\d+)*(?:\.post\d+)?"
        )
        if not re.fullmatch(stable, version):
            errors.append(f"{label}: not a stable numeric release")
            continue
        if ecosystem == "npm":
            timestamp = data.get("time", {}).get(version)
            if version not in data.get("versions", {}) or not timestamp:
                errors.append(f"{label}: unavailable CFS version or publication date")
                continue
        else:
            files = data.get("releases", {}).get(version, [])
            timestamps = [
                file["upload_time_iso_8601"]
                for file in files
                if not file.get("yanked")
            ]
            if not timestamps:
                errors.append(f"{label}: no non-yanked upstream release")
                continue
            timestamp = min(timestamps)
        published = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
        if published >= cutoff:
            errors.append(f"{label}: published {timestamp}, after cutoff")
    return errors


def main():
    config = dict(
        line.split("=", 1)
        for line in (ROOT / ".npmrc").read_text().splitlines()
        if line and not line.startswith("#")
    )
    cutoff = datetime.fromisoformat(config["before"].replace("Z", "+00:00"))
    packages = {}
    npm = json.loads((ROOT / "package-lock.json").read_text())
    for path, package in npm["packages"].items():
        if path and "version" in package:
            name = path.rsplit("node_modules/", 1)[1]
            packages.setdefault(("npm", name), set()).add(package["version"])
    python = tomllib.loads((ROOT / "uv.lock").read_text())
    for package in python["package"]:
        if "registry" in package["source"]:
            packages.setdefault(("pypi", package["name"]), set()).add(
                package["version"]
            )
    tasks = [
        (ecosystem, name, versions)
        for (ecosystem, name), versions in packages.items()
    ]
    with ThreadPoolExecutor(max_workers=6) as pool:
        errors = [
            error
            for result in pool.map(lambda task: check(task, cutoff), tasks)
            for error in result
        ]
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    count = sum(len(versions) for versions in packages.values())
    print(
        f"All {count} locked package versions are stable and published before "
        f"{cutoff.isoformat()}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
