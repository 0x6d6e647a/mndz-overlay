"""Packaging checks; set CADDY_ANALYZE_BIN to also exercise a built binary.

Run with: python3 -m unittest discover -s tests -v
"""

import itertools
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET


PACKAGE = Path(__file__).resolve().parents[1] / "net-analyzer/caddy-analyzer"
EBUILD = PACKAGE / "caddy-analyzer-0.7.4.ebuild"
BINARY = os.environ.get("CADDY_ANALYZE_BIN")


def phase(command, flags=(), binary=None, text=None):
    """Run an ebuild phase with recording substitutes for Portage helpers."""
    with tempfile.TemporaryDirectory(prefix="caddy package '") as directory:
        root = Path(directory)
        ebuild = root / "package.ebuild"
        ebuild.write_text(text if text is not None else EBUILD.read_text())
        if binary:
            (root / "caddy-analyze").symlink_to(binary)
        script = r'''
inherit() { :; }
die() { printf '%s\n' "$*" >&2; exit 1; }
use() { [[ " ${TEST_USE} " == *" $1 "* ]]; }
ego() { printf 'ego %s cgo=%s\n' "$*" "${CGO_ENABLED}"; }
einstalldocs() { printf 'docs\n'; }
dobin() { printf 'binary %s\n' "$1"; }
newbashcomp() { printf 'bash %s\n' "$2"; }
newfishcomp() { printf 'fish %s\n' "$2"; }
newzshcomp() { printf 'zsh %s\n' "$2"; }
source "$1" || exit 1
eval "$2"
'''
        env = dict(os.environ, T=directory, PV="0.7.4", P="caddy-analyzer-0.7.4",
                   FILESDIR=str(PACKAGE / "files"), TEST_USE=" ".join(flags),
                   XDG_CONFIG_HOME=str(root / "config"))
        return subprocess.run(["bash", "-c", script, "test", str(ebuild), command],
                              env=env, capture_output=True, text=True, timeout=30)


class PackagingTests(unittest.TestCase):
    def test_metadata(self):
        metadata = ET.parse(PACKAGE / "metadata.xml").getroot()
        self.assertEqual(metadata.tag, "pkgmetadata")
        self.assertEqual(metadata.find("upstream/remote-id").attrib, {"type": "github"})
        self.assertEqual(metadata.findtext("upstream/remote-id"), "lenny-ts/caddy-analyzer")
        self.assertTrue(metadata.findtext("upstream/bugs-to").endswith("/issues"))

    def assert_compile_contract(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("github.com/lenny-ts/caddy-analyzer/cmd.Version=0.7.4", result.stdout)
        self.assertIn("./cmd/caddy-analyze cgo=0", result.stdout)
        self.assertIn("-buildvcs=false", result.stdout)

    def test_compile_contract(self):
        self.assert_compile_contract(phase("src_compile"))

    def test_version_mutation_is_detected(self):
        mutant = EBUILD.read_text().replace("cmd.Version", "main.Version")
        result = phase("src_compile", text=mutant)
        with self.assertRaises(AssertionError):
            self.assert_compile_contract(result)

    def test_test_phase_and_restriction(self):
        result = phase('src_test; printf "%s\\n" "$IUSE" "$RESTRICT" "$XDG_CONFIG_HOME"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ego test ./...", result.stdout)
        self.assertIn("!test? ( test )", result.stdout)
        self.assertTrue(result.stdout.rstrip().endswith("/config"))

    def test_licenses_and_toolchain(self):
        result = phase('printf "%s\\n" "$LICENSE" "$BDEPEND" "${PATCHES[@]}"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines()[0], "Apache-2.0 BSD ISC MIT")
        self.assertIn(">=dev-lang/go-1.25.13:=", result.stdout)
        self.assertIn("offline-geoip.patch", result.stdout)

    def test_failed_completion_is_never_installed(self):
        with tempfile.TemporaryDirectory() as directory:
            binary = Path(directory) / "fail"
            binary.write_text("#!/bin/bash\nprintf 'partial completion\\n'\nexit 1\n")
            binary.chmod(0o755)
            for shell in ("bash", "fish", "zsh"):
                with self.subTest(shell=shell):
                    result = phase("src_install", [f"{shell}-completion"], str(binary))
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn(f"failed to generate {shell} completion", result.stderr)
                    self.assertNotIn(f"{shell} ", result.stdout)


@unittest.skipUnless(BINARY, "set CADDY_ANALYZE_BIN to a built caddy-analyze")
class BinaryTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.env = dict(os.environ, XDG_CONFIG_HOME=self.directory.name)

    def run_binary(self, *args, data=None, success=True):
        result = subprocess.run([BINARY, *args], input=data, text=True, capture_output=True,
                                cwd=self.directory.name, env=self.env, timeout=30)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def test_version(self):
        self.assertEqual(self.run_binary("--version").stdout.strip(), "caddy-analyze version 0.7.4")

    def test_command_routes(self):
        for command in ("tail", "top", "diff", "guard", "config", "block", "unban",
                        "export-sigma", "baseline", "compare", "completion"):
            with self.subTest(command=command):
                self.assertIn("Usage:", self.run_binary(command, "--help").stdout)

    def test_completion_use_flag_combinations(self):
        shells = ("bash", "fish", "zsh")
        for enabled in itertools.product((False, True), repeat=3):
            flags = [f"{shell}-completion" for shell, active in zip(shells, enabled) if active]
            with self.subTest(flags=flags):
                result = phase("src_install", flags, BINARY)
                self.assertEqual(result.returncode, 0, result.stderr)
                for shell, active in zip(shells, enabled):
                    self.assertEqual(f"{shell} " in result.stdout, active)

    def test_json_report_schema_and_permutation_invariance(self):
        entries = [dict(level="info", ts=1700000000 + i, logger="http.log.access",
                        msg="handled request", request=dict(method="GET", uri=f"/item/{i}",
                        remote_ip="192.0.2.1", host="example.test"), status=status,
                        size=1024, duration=0.005) for i, status in enumerate((200, 404, 500))]
        for ordered in itertools.permutations(entries):
            report = json.loads(self.run_binary("--no-auto-download", "-f", "json", "-",
                                data="".join(json.dumps(row) + "\n" for row in ordered)).stdout)
            self.assertEqual(report["total_requests"], 3)
            self.assertEqual(report["parse_errors"], 0)
            self.assertEqual(report["status_codes"]["by_code"], {"200": 1, "404": 1, "500": 1})
            self.assertEqual(report["response_size"]["total"], 3072)

    def test_adversarial_flags_fail_without_creating_reports(self):
        output = Path(self.directory.name) / "report.json"
        for args in (("--ip", "invalid-cidr"), ("--custom-patterns", "missing.json"),
                     ("--definitely-not-a-flag",)):
            with self.subTest(args=args):
                self.run_binary("--no-auto-download", "-o", str(output), *args, "-",
                                data="{}\n", success=False)
                self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
