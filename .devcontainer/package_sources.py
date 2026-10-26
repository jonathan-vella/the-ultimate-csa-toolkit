"""Validate selected HTTPS feeds and the reviewed toolkit lock destinations."""

import argparse
import json
import os
from pathlib import Path
import sys
import tomllib
from urllib.parse import urlsplit


ROOT = Path(__file__).resolve().parent
NPM_DEFAULT = "https://packagefeedproxy.microsoft.io/npm/"
PYTHON_DEFAULT = "https://packagefeedproxy.microsoft.io/pypi/simple/"
POWERSHELL_DEFAULT = "https://packagefeedproxy.microsoft.io/powershell/v2"


def https_source(value):
    """Reject unsafe inputs without including their potentially secret values."""
    try:
        url = urlsplit(value)
        valid = (
            url.scheme == "https"
            and url.hostname
            and url.port in (None, 443)
            and not url.username
            and not url.password
            and not url.query
            and not url.fragment
            and not any(char.isspace() or char in "\\$`\"'" for char in value)
            and "//" not in url.path
            and all(part not in (".", "..") for part in url.path.split("/"))
        )
    except ValueError:
        valid = False
    if not valid:
        raise ValueError(
            "Feeds must be HTTPS host/path URLs without credentials or query strings."
        )
    return value


def selected_sources(env=None):
    env = os.environ if env is None else env
    npm = https_source(env.get("NPM_CONFIG_REGISTRY", NPM_DEFAULT))
    python = https_source(env.get("UV_DEFAULT_INDEX", PYTHON_DEFAULT))
    https_source(env.get("CSA_POWERSHELL_REPOSITORY_URL") or POWERSHELL_DEFAULT)
    for name in (
        "npm_config_registry",
        "PNPM_CONFIG_REGISTRY",
        "COREPACK_NPM_REGISTRY",
        "YARN_NPM_REGISTRY_SERVER",
    ):
        if name in env and https_source(env[name]) != npm:
            raise ValueError(f"{name} conflicts with the selected npm source.")
    for name in ("UV_INDEX_URL", "PIP_INDEX_URL"):
        if name in env and https_source(env[name]) != python:
            raise ValueError(f"{name} conflicts with the selected Python source.")
    return npm, python


def check_locks(root=ROOT, env=None):
    npm, python = selected_sources(env)
    sources = json.loads((root / "package-sources.json").read_text())
    if (npm, python) != (sources["npmRegistry"], sources["pythonIndex"]):
        raise ValueError(
            "Selected feeds differ from the toolkit locks. Regenerate and review "
            "the locks and package-sources.json for the approved feeds before building."
        )
    config = dict(
        line.split("=", 1) for line in (root / ".npmrc").read_text().splitlines()
        if line and not line.startswith("#")
    )
    if config["registry"] != npm:
        raise ValueError(".npmrc differs from the reviewed npm source.")
    for key in ("npmArtifactPrefixes", "pythonArtifactPrefixes"):
        if not sources[key]:
            raise ValueError("A reviewed artifact prefix list is empty.")
        for prefix in sources[key]:
            if not https_source(prefix).endswith("/"):
                raise ValueError("Artifact prefixes must end with a path separator.")
    npm_lock = json.loads((root / "package-lock.json").read_text())
    for package in npm_lock["packages"].values():
        if "resolved" in package:
            artifact = https_source(package["resolved"])
            if not artifact.startswith(tuple(sources["npmArtifactPrefixes"])):
                raise ValueError("npm lock contains an unreviewed artifact destination.")
            if not package.get("integrity"):
                raise ValueError("npm lock artifact is missing integrity.")
    python_lock = tomllib.loads((root / "uv.lock").read_text())
    for package in python_lock["package"]:
        if "registry" not in package["source"]:
            continue
        if package["source"]["registry"] != python:
            raise ValueError("uv lock source differs from the selected Python index.")
        artifacts = package.get("wheels", []) + (
            [package["sdist"]] if "sdist" in package else []
        )
        for artifact in artifacts:
            url = https_source(artifact["url"])
            if not url.startswith(tuple(sources["pythonArtifactPrefixes"])):
                raise ValueError("uv lock contains an unreviewed artifact destination.")
            if not artifact.get("hash", "").startswith("sha256:"):
                raise ValueError("uv lock artifact is missing SHA-256 integrity.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config-only", action="store_true")
    args = parser.parse_args()
    try:
        if args.config_only:
            selected_sources()
        else:
            check_locks()
    except (ValueError, KeyError, OSError) as error:
        # JSON/TOML parse errors can contain source text; do not echo it.
        if isinstance(error, (json.JSONDecodeError, tomllib.TOMLDecodeError)):
            print("Package source configuration could not be parsed.", file=sys.stderr)
        elif isinstance(error, ValueError):
            print(str(error), file=sys.stderr)
        else:
            print("Package source configuration is missing or unreadable.", file=sys.stderr)
        return 1
    print("Package source checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
