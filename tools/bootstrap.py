#!/usr/bin/env python3
"""Install the pinned, checksum-verified Godot editor and required export templates."""
import hashlib
import os
from pathlib import Path
import urllib.request
import zipfile

VERSION = "4.7.2"
ASSETS = {
    "Godot_v4.7.2-stable_linux.x86_64.zip": "9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65",
    "Godot_v4.7.2-stable_export_templates.tpz": "ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079",
}
tool_dir = Path(os.environ.get("HOPAN_TOOL_DIR", f"/workspace/tools/godot-{VERSION}"))
data_dir = Path(os.environ.get("XDG_DATA_HOME", "/workspace/.local/share"))
templates = data_dir / "godot" / "export_templates" / f"{VERSION}.stable"


def setup():
    tool_dir.mkdir(parents=True, exist_ok=True)
    templates.mkdir(parents=True, exist_ok=True)
    for name, expected in ASSETS.items():
        archive = tool_dir / name
        if not archive.exists():
            temporary = archive.with_suffix(archive.suffix + ".partial")
            urllib.request.urlretrieve(
                f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/{name}",
                temporary,
            )
            temporary.rename(archive)
        with archive.open("rb") as f:
            actual = hashlib.file_digest(f, "sha512").hexdigest()
        if actual != expected:
            raise RuntimeError(f"Checksum mismatch for {archive}; refusing to use it")
        with zipfile.ZipFile(archive) as z:
            for entry in z.infolist():
                filename = Path(entry.filename).name
                if name.endswith(".tpz") and not (
                    filename.startswith("web_") or
                    filename.startswith("windows_") or filename == "version.txt"
                ):
                    continue
                if entry.is_dir():
                    continue
                destination = (templates if name.endswith(".tpz") else tool_dir) / filename
                content = z.read(entry)
                # Check extracted content too, so repeat runs repair changed files.
                if not destination.exists() or hashlib.sha256(destination.read_bytes()).digest() != hashlib.sha256(content).digest():
                    destination.write_bytes(content)
        print(f"Verified and prepared {name}")
    binary = tool_dir / f"Godot_v{VERSION}-stable_linux.x86_64"
    binary.chmod(0o755)
    print(f"Godot ready: {binary}")


if __name__ == "__main__":
    setup()
