#!/usr/bin/env python3
"""Generate public release metadata; signing happens afterward without key export."""
from datetime import datetime, timezone
from email.utils import format_datetime
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

config = json.loads(Path("release/config.json").read_text())
archive, signature, output = sys.argv[1:]
namespace = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", namespace)
rss = ET.Element("rss", version="2.0")
channel = ET.SubElement(rss, "channel")
ET.SubElement(channel, "title").text = "WisprFlowIsDead updates"
ET.SubElement(channel, "link").text = config["feedURL"]
item = ET.SubElement(channel, "item")
ET.SubElement(item, "title").text = "WisprFlowIsDead " + config["version"]
ET.SubElement(item, "pubDate").text = format_datetime(datetime.now(timezone.utc))
for key, value in [("version", config["build"]), ("shortVersionString", config["version"]), ("minimumSystemVersion", config["minimumSystemVersion"])]:
    ET.SubElement(item, "{" + namespace + "}" + key).text = value
ET.SubElement(item, "enclosure", {
    "url": "https://github.com/tommy-muckstack/wisprflowisdead/releases/download/v" + config["version"] + "/" + Path(archive).name,
    "length": str(Path(archive).stat().st_size),
    "type": "application/octet-stream",
    "{" + namespace + "}edSignature": signature,
})
ET.indent(rss)
ET.ElementTree(rss).write(output, encoding="utf-8", xml_declaration=True)
