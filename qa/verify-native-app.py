#!/usr/bin/env python3
"""Verify the assembled bundle, including updater helpers and runtime resources."""
import base64
import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys

app = Path(sys.argv[1]).resolve()
config = json.loads(Path("release/config.json").read_text())
with (app / "Contents/Info.plist").open("rb") as file:
    info = plistlib.load(file)
assert info["CFBundleIdentifier"] == "com.muckstack.wisprflowisdead"
assert info["CFBundleVersion"] == config["build"]
assert info["CFBundleShortVersionString"] == config["version"]
assert info["SUFeedURL"] == config["feedURL"]
assert info["SUPublicEDKey"] == config["sparklePublicKey"]
assert len(base64.b64decode(info["SUPublicEDKey"], validate=True)) == 32
for setting in ["SUEnableAutomaticChecks", "SUAutomaticallyUpdate", "SUVerifyUpdateBeforeExtraction", "SURequireSignedFeed"]:
    assert info[setting] is True, setting
assert info["SUSendProfileInfo"] is False
framework = app / "Contents/Frameworks/Sparkle.framework"
for executable in ["Sparkle", "Versions/B/Autoupdate", "Versions/B/Updater.app/Contents/MacOS/Updater", "Versions/B/XPCServices/Installer.xpc/Contents/MacOS/Installer", "Versions/B/XPCServices/Downloader.xpc/Contents/MacOS/Downloader"]:
    assert os.access(framework / executable, os.X_OK), executable
assert (framework / "Versions/Current").is_symlink()
binary = app / "Contents/MacOS/WisprFlowIsDead"
assert "@rpath/Sparkle.framework/Versions/B/Sparkle" in subprocess.check_output(["otool", "-L", str(binary)], text=True)
assert "@executable_path/../Frameworks" in subprocess.check_output(["otool", "-l", str(binary)], text=True)
for name in ["Figtree-Variable.ttf", "EBGaramond-Variable.ttf", "Tombstone.png", "AppIcon.png"]:
    matches = list((app / "Contents/Resources").rglob(name))
    assert len(matches) == 1 and matches[0].stat().st_size > 0, name
icon = app / "Contents/Resources/AppIcon.icns"
assert icon.read_bytes()[:4] == b"icns"
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
print(json.dumps({"bundle": str(app), "version": info["CFBundleShortVersionString"], "build": info["CFBundleVersion"], "sparkle": "embedded, linked and configured", "resources": "present", "signature": "valid"}))
