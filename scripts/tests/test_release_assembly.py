"""Release uploads must retain their bytes and contain exactly one installer."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ASSEMBLER = Path(__file__).resolve().parents[1] / "assemble-release.py"


class ReleaseAssembly(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "release").mkdir()
        (self.root / "release/config.json").write_text('{"version":"0.1.1"}')
        self.payload = self.root / "payload"
        self.payload.mkdir()

    def fixture(self, kind="dmg"):
        (self.root / "release/config.json").write_text(json.dumps({"version": "0.1.1", "installerFormat": kind}))
        names = ["WisprFlowIsDead-0.1.1.zip", f"WisprFlowIsDead-0.1.1.{kind}", "appcast.xml"]
        self.contents = {name: b"\x00\xffrelease-data-" + name.encode() for name in names}
        files = []
        for i, (name, data) in enumerate(self.contents.items()):
            parts = [f"file-{i}.part000", f"file-{i}.part001"]
            (self.payload / parts[0]).write_bytes(data[:5])
            (self.payload / parts[1]).write_bytes(data[5:])
            files.append({"name": name, "parts": parts, "sha256": hashlib.sha256(data).hexdigest()})
        return {"version": "0.1.1", "sourceCommit": "a" * 40, "files": files}

    def assemble(self, manifest):
        (self.payload / "manifest.json").write_text(json.dumps(manifest))
        return subprocess.run([sys.executable, str(ASSEMBLER), "payload", "output"], cwd=self.root, capture_output=True)

    def test_dmg_and_legacy_pkg_reconstruct_identical_bytes(self):
        for kind in ["dmg", "pkg"]:
            with self.subTest(kind=kind):
                result = self.assemble(self.fixture(kind))
                self.assertEqual(result.returncode, 0, result.stderr.decode())
                for name, original in self.contents.items():
                    self.assertEqual((self.root / "output" / name).read_bytes(), original)

    def test_tampered_chunk_is_rejected(self):
        manifest = self.fixture()
        (self.payload / manifest["files"][0]["parts"][0]).write_bytes(b"changed")
        self.assertNotEqual(self.assemble(manifest).returncode, 0)

    def test_duplicate_asset_is_rejected(self):
        manifest = self.fixture()
        manifest["files"].append(manifest["files"][0])
        self.assertNotEqual(self.assemble(manifest).returncode, 0)

    def test_chunk_cannot_escape_payload_directory(self):
        manifest = self.fixture()
        manifest["files"][0]["parts"] = ["../outside.part000"]
        self.assertNotEqual(self.assemble(manifest).returncode, 0)

    def test_unknown_installer_and_wrong_version_are_rejected(self):
        self.assertNotEqual(self.assemble(self.fixture("exe")).returncode, 0)
        manifest = self.fixture()
        manifest["version"] = "0.1.0"
        self.assertNotEqual(self.assemble(manifest).returncode, 0)

    def test_cannot_substitute_pkg_for_required_dmg(self):
        manifest = self.fixture("pkg")
        (self.root / "release/config.json").write_text('{"version":"0.1.1","installerFormat":"dmg"}')
        self.assertNotEqual(self.assemble(manifest).returncode, 0)


if __name__ == "__main__":
    unittest.main()
