#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' \
    'Toolkit updates are reviewed rebuilds, not in-place global upgrades.' \
    'Update .devcontainer/tool-versions.env and matching releases.sha256 together.' \
    'Update the image digest and Azure CLI RPM version in Dockerfile when applicable.' \
    'Update Python/npm manifests, regenerate uv.lock and package-lock.json, and review the diff.' \
    'Use approved packagefeedproxy.microsoft.io npm/PyPI endpoints and stable releases older than seven days.' \
    'Update .npmrc before cutoff; resolve npm from a fresh lock and run check-package-age.py.' \
    'Rebuild through Dev Containers, then run smoke-test.sh on native x64 and ARM64.' \
    'Browser packages and their downloaded revisions must be updated together.'
bash /opt/csa-toolkit/smoke-test.sh
