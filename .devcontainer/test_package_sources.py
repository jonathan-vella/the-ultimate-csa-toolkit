"""Offline regression checks: uv run --no-project test_package_sources.py."""

from datetime import datetime
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from package_sources import (
    NPM_DEFAULT,
    PYTHON_DEFAULT,
    ROOT,
    check_locks,
    https_source,
    selected_sources,
)


class SourceTests(unittest.TestCase):
    def test_current_locks(self):
        check_locks(env={})

    def test_source_inputs(self):
        for value in (
            "http://example.org/feed/", "https://user:secret@example.org/",
            "https://example.org/?token=secret", "https://example.org/#secret",
            "https://example.org:8080/", "https://example.org/../feed/",
            "https://example.org/with space/", "https://example.org\\feed/",
            "https://https://example.org/", "",
        ):
            with self.subTest(value=value), self.assertRaises(ValueError):
                https_source(value)
        self.assertEqual(https_source("https://feeds.example.org/team/"),
                         "https://feeds.example.org/team/")

    def test_alias_conflicts(self):
        for name in ("npm_config_registry", "PNPM_CONFIG_REGISTRY",
                     "COREPACK_NPM_REGISTRY", "YARN_NPM_REGISTRY_SERVER",
                     "UV_INDEX_URL", "PIP_INDEX_URL"):
            with self.subTest(name=name), self.assertRaisesRegex(
                ValueError, "conflicts"
            ):
                selected_sources({name: "https://feeds.example.org/team/"})
        self.assertEqual(selected_sources({}), (NPM_DEFAULT, PYTHON_DEFAULT))
        selected_sources({"CSA_POWERSHELL_REPOSITORY_URL": ""})

    def test_feed_override_requires_reviewed_locks(self):
        with self.assertRaisesRegex(ValueError, "Regenerate and review"):
            check_locks(
                env={"NPM_CONFIG_REGISTRY": "https://feeds.example.org/npm/"}
            )

    def test_cli_redacts_invalid_sources(self):
        env = os.environ | {
            "NPM_CONFIG_REGISTRY": "https://user:do-not-print@example.org/"
        }
        result = subprocess.run(
            [sys.executable, str(ROOT / "package_sources.py"), "--config-only"],
            env=env, text=True, capture_output=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("do-not-print", result.stdout + result.stderr)

    def test_age_audit_uses_selected_registry(self):
        spec = importlib.util.spec_from_file_location(
            "age_audit", ROOT / "check-package-age.py"
        )
        audit = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(audit)
        response = {
            "time": {"1.0.0": "2026-09-01T00:00:00Z"},
            "versions": {"1.0.0": {}},
        }
        env = {"NPM_CONFIG_REGISTRY": "https://feeds.example.org/npm/"}
        with patch.dict(os.environ, env, clear=True), patch.object(
            audit, "metadata", return_value=response
        ) as metadata:
            errors = audit.check(
                ("npm", "@team/test", {"1.0.0"}),
                datetime.fromisoformat("2026-10-01T00:00:00+00:00"),
            )
            self.assertEqual(errors, [])
            metadata.assert_called_once_with(
                "https://feeds.example.org/npm/%40team%2Ftest"
            )

    def test_custom_feed_and_artifact_destinations(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            npm = "https://feeds.example.org/npm/"
            python = "https://feeds.example.org/python/simple/"
            sources = {
                "npmRegistry": npm, "pythonIndex": python,
                "npmArtifactPrefixes": ["https://artifacts.example.org/npm/"],
                "pythonArtifactPrefixes": ["https://artifacts.example.org/python/"],
            }
            lock = {"packages": {"node_modules/test": {
                "resolved": "https://artifacts.example.org/npm/test.tgz",
                "integrity": "sha512-fixture",
            }}}
            (root / "package-sources.json").write_text(json.dumps(sources))
            (root / ".npmrc").write_text(
                f"registry={npm}\nbefore=2026-10-01T13:05:02Z\n"
            )
            (root / "package-lock.json").write_text(json.dumps(lock))
            (root / "uv.lock").write_text(
                '[[package]]\nname = "fixture"\n'
                f'source = {{ registry = "{python}" }}\n'
                'wheels = [{ url = "https://artifacts.example.org/python/test.whl", '
                'hash = "sha256:fixture" }]\n'
            )
            env = {"NPM_CONFIG_REGISTRY": npm, "UV_DEFAULT_INDEX": python}
            check_locks(root, env)
            package = lock["packages"]["node_modules/test"]
            package["resolved"] = "https://public.example.org/test.tgz"
            (root / "package-lock.json").write_text(json.dumps(lock))
            with self.assertRaisesRegex(ValueError, "unreviewed artifact"):
                check_locks(root, env)
            package["resolved"] = "https://artifacts.example.org/npm/test.tgz"
            del package["integrity"]
            (root / "package-lock.json").write_text(json.dumps(lock))
            with self.assertRaisesRegex(ValueError, "missing integrity"):
                check_locks(root, env)

    def test_build_runtime_contract(self):
        config = json.loads((ROOT / "devcontainer.json").read_text())
        dockerfile = (ROOT / "Dockerfile").read_text()
        host = "${localEnv:CSA_NPM_REGISTRY_HOST_PATH:packagefeedproxy.microsoft.io/npm/}"
        python = "${localEnv:CSA_PYPI_INDEX_HOST_PATH:packagefeedproxy.microsoft.io/pypi/simple/}"
        self.assertEqual(config["build"]["args"]["CSA_NPM_REGISTRY_HOST_PATH"], host)
        self.assertEqual(config["build"]["args"]["CSA_PYPI_INDEX_HOST_PATH"], python)
        for key in ("NPM_CONFIG_REGISTRY", "PNPM_CONFIG_REGISTRY",
                    "COREPACK_NPM_REGISTRY", "YARN_NPM_REGISTRY_SERVER"):
            self.assertEqual(config["containerEnv"][key], f"https://{host}")
            self.assertIn(f'{key}="https://${{CSA_NPM_REGISTRY_HOST_PATH}}"', dockerfile)
        for key in ("UV_DEFAULT_INDEX", "UV_INDEX_URL", "PIP_INDEX_URL"):
            self.assertEqual(config["containerEnv"][key], f"https://{python}")
            self.assertIn(f'{key}="https://${{CSA_PYPI_INDEX_HOST_PATH}}"', dockerfile)
        # Full URLs with colon-containing defaults are not safe localEnv substitutions.
        self.assertEqual(config["containerEnv"]["CSA_POWERSHELL_REPOSITORY_URL"],
                         "${localEnv:CSA_POWERSHELL_REPOSITORY_URL}")
        self.assertEqual(config["build"]["args"]["CSA_POWERSHELL_REPOSITORY_URL"],
                         "${localEnv:CSA_POWERSHELL_REPOSITORY_URL}")
        self.assertLess(dockerfile.index("package_sources.py --config-only"),
                        dockerfile.index("install-tools.sh \"$TARGETARCH\""))
        self.assertLess(dockerfile.index("python3 package_sources.py"),
                        dockerfile.index("uv sync --locked"))

    def test_npm_environment_precedence(self):
        npm = shutil.which("npm.cmd" if os.name == "nt" else "npm")
        self.assertIsNotNone(npm, "npm is required for the configuration regression check")
        env = {key: value for key, value in os.environ.items()
               if key.upper() != "NPM_CONFIG_REGISTRY"}
        env["NPM_CONFIG_REGISTRY"] = "https://feeds.example.org/npm/"
        result = subprocess.run(
            [npm, "config", "get", "registry"], cwd=ROOT, env=env,
            check=True, text=True, capture_output=True,
        )
        self.assertEqual(result.stdout.strip(), env["NPM_CONFIG_REGISTRY"])


class LauncherTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="csa launcher ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repository with spaces"
        self.scripts = self.repo / ".devcontainer"
        self.bin = self.root / "bin"
        self.scripts.mkdir(parents=True)
        self.bin.mkdir()
        for name in ("open-microsoft.sh", "open-microsoft.ps1"):
            shutil.copy2(ROOT / name, self.scripts / name)
        self.capture = self.root / "capture.txt"
        self.env = os.environ.copy()
        self.env.update({
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "CSA_TEST_CAPTURE": str(self.capture), "CSA_TEST_EXIT": "0",
            "CSA_NPM_REGISTRY_HOST_PATH": "previous.example.org/npm/",
            "CSA_PYPI_INDEX_HOST_PATH": "previous.example.org/python/",
            "CSA_POWERSHELL_REPOSITORY_URL": "https://previous.example.org/powershell/",
        })
        if os.name == "nt":
            (self.bin / "code.cmd").write_text(
                '@echo off\n'
                '(echo %~1&echo %CSA_NPM_REGISTRY_HOST_PATH%&'
                'echo %CSA_PYPI_INDEX_HOST_PATH%&echo %CSA_POWERSHELL_REPOSITORY_URL%) '
                '> "%CSA_TEST_CAPTURE%"\nexit /b %CSA_TEST_EXIT%\n'
            )
        stub = self.bin / "code"
        stub.write_text(
            '#!/usr/bin/env bash\n'
            'printf "%s\\n" "$1" "$CSA_NPM_REGISTRY_HOST_PATH" '
            '"$CSA_PYPI_INDEX_HOST_PATH" "$CSA_POWERSHELL_REPOSITORY_URL" '
            '"${WSLENV:-}" > "$CSA_TEST_CAPTURE"\nexit "$CSA_TEST_EXIT"\n',
            newline="\n",
        )
        stub.chmod(0o755)

    def assert_capture(self):
        lines = self.capture.read_text().splitlines()
        self.assertEqual(Path(lines[0]).resolve(), self.repo.resolve())
        self.assertEqual(lines[1:4], [
            "packagefeedproxy.microsoft.io/npm/",
            "packagefeedproxy.microsoft.io/pypi/simple/",
            "https://packagefeedproxy.microsoft.io/powershell/v2",
        ])
        return lines

    def test_bash_launch_and_wsl_forwarding(self):
        bash = shutil.which("bash")
        self.assertIsNotNone(bash, "bash is required for the launcher regression checks")
        self.env.update({
            "WSL_DISTRO_NAME": "test",
            "WSLENV": "KEEP/p:CSA_NPM_REGISTRY_HOST_PATH/u:OTHER:CSA_PYPI_INDEX_HOST_PATH",
        })
        result = subprocess.run(
            [bash, str(self.scripts / "open-microsoft.sh")],
            env=self.env, text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        lines = self.assert_capture()
        self.assertEqual(lines[4],
                         "KEEP/p:OTHER:CSA_NPM_REGISTRY_HOST_PATH:"
                         "CSA_PYPI_INDEX_HOST_PATH:CSA_POWERSHELL_REPOSITORY_URL")
        self.env["CSA_TEST_EXIT"] = "23"
        result = subprocess.run([bash, str(self.scripts / "open-microsoft.sh")],
                                env=self.env, capture_output=True)
        self.assertEqual(result.returncode, 23)

    @unittest.skipIf(os.name == "nt", "Missing-CLI isolation uses Unix executable links")
    def test_bash_missing_cli(self):
        bash = shutil.which("bash")
        self.assertIsNotNone(bash)
        env = self.env | {"PATH": str(self.root / "empty")}
        result = subprocess.run([bash, str(self.scripts / "open-microsoft.sh")],
                                env=env, capture_output=True)
        self.assertEqual(result.returncode, 127)
        self.assertIn(b"VS Code CLI is required", result.stderr)

    def test_powershell_launch_and_environment_restoration(self):
        shells = [shutil.which("pwsh")]
        if os.name == "nt":
            shells.append(shutil.which("powershell"))
        for shell in shells:
            self.assertIsNotNone(shell, "PowerShell is required for launcher checks")
            with self.subTest(shell=shell):
                script = str(self.scripts / "open-microsoft.ps1").replace("'", "''")
                command = (
                    f". '{script}'; "
                    "if ($env:CSA_NPM_REGISTRY_HOST_PATH -ne 'previous.example.org/npm/' "
                    "-or $env:CSA_PYPI_INDEX_HOST_PATH -ne 'previous.example.org/python/' "
                    "-or $env:CSA_POWERSHELL_REPOSITORY_URL -ne 'https://previous.example.org/powershell/') "
                    "{ throw 'Calling environment was not restored' }"
                )
                result = subprocess.run([shell, "-NoProfile", "-Command", command],
                                        env=self.env, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assert_capture()
                env = self.env | {"CSA_TEST_EXIT": "23"}
                result = subprocess.run([shell, "-NoProfile", "-File",
                                         str(self.scripts / "open-microsoft.ps1")],
                                        env=env, capture_output=True)
                self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
