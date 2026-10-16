#!/usr/bin/env python3
"""Reassemble a connector-uploaded release without storing binaries on main."""
import hashlib
import json
from pathlib import Path
import re
import sys

source, output = map(Path, sys.argv[1:])
manifest = json.loads((source / "manifest.json").read_text())
config = json.loads(Path("release/config.json").read_text())
version = config["version"]
assert manifest["version"] == version and re.fullmatch(r"\d+\.\d+\.\d+", version)
assert re.fullmatch(r"[a-f0-9]{40}", manifest["sourceCommit"])
names = [file["name"] for file in manifest["files"]]
assert len(names) == len(set(names)) == 3
base = {f"WisprFlowIsDead-{version}.zip", "appcast.xml"}
kind = config.get("installerFormat", "pkg")
assert kind in ["pkg", "dmg"]
assert set(names) == base | {f"WisprFlowIsDead-{version}.{kind}"}
output.mkdir(parents=True, exist_ok=True)
checksums = []
for file in manifest["files"]:
    chunks = []
    for part in file["parts"]:
        assert re.fullmatch(r"[a-z0-9-]+\.part\d{3}", part)
        chunks.append((source / part).read_bytes())
    data = b"".join(chunks)
    digest = hashlib.sha256(data).hexdigest()
    assert digest == file["sha256"], file["name"]
    (output / file["name"]).write_bytes(data)
    checksums.append(digest + "  " + file["name"])
(output / "SHA256SUMS").write_text("\n".join(checksums) + "\n")
print(version)
