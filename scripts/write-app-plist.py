#!/usr/bin/env python3
"""Keep development and release bundle/update metadata identical."""
import json
import os
from pathlib import Path
import plistlib
import sys

config = json.loads(Path("release/config.json").read_text())
plist = {
    "CFBundleExecutable": "WisprFlowIsDead",
    "CFBundleIdentifier": "com.muckstack.wisprflowisdead",
    "CFBundleName": "WisprFlowIsDead",
    "CFBundleShortVersionString": config["version"],
    "CFBundleVersion": config["build"],
    "CFBundlePackageType": "APPL",
    "LSMinimumSystemVersion": config["minimumSystemVersion"],
    "LSUIElement": True,
    "CFBundleIconFile": "AppIcon",
    "NSAudioCaptureUsageDescription": "Notetaker records what other people say in your calls, on this Mac only, when you start a recording.",
    "NSMicrophoneUsageDescription": "WisprFlowIsDead listens only while you hold your dictation shortcut, and transcribes on this Mac.",
    "NSAppleEventsUsageDescription": "WisprFlowIsDead types your dictation into the app you are using.",
    "SUFeedURL": config["feedURL"],
    "SUPublicEDKey": config["sparklePublicKey"],
    "SUEnableAutomaticChecks": True,
    "SUAutomaticallyUpdate": True,
    "SUSendProfileInfo": False,
    "SUVerifyUpdateBeforeExtraction": True,
    "SURequireSignedFeed": True,
}
if os.environ.get("SOURCE_COMMIT"):
    plist["WFSourceRevision"] = os.environ["SOURCE_COMMIT"]
with open(sys.argv[1], "wb") as file:
    plistlib.dump(plist, file)
