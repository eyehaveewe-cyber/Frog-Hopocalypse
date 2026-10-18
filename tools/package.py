#!/usr/bin/env python3
"""Package completed release exports without changing source or level data."""
from pathlib import Path
import hashlib
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"

for name, folder, instructions in [
    ("Hopan-web", "web", "Extract this archive, then serve this entire folder over HTTP/HTTPS.\nFor local desktop play: python3 -m http.server 8000\nVisit the local server in a WebGL 2 browser. Do not open index.html as a file.\nUse WASD/arrows to move, M for overhead map / return to 3D, R to retry, Esc to pause.\nChoose Level editor to build maps. Export JSON for portable backups.\n"),
    ("Hopan-windows", "windows", "Extract this archive and run Hopan.exe on Windows x86-64.\nUse WASD/arrows to move, M for overhead map / return to 3D, R to retry, Esc to pause.\nChoose Level editor to build maps. Export JSON for portable backups.\nThis executable was exported on Linux; Windows execution still needs testing.\n"),
]:
    files = sorted((BUILD / folder).iterdir())
    assert files, f"Build {folder} first"
    archive = BUILD / f"{name}.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for file in files:
            if file.is_file():
                z.write(file, file.name)
        z.writestr("PLAY-README.txt", instructions)
        z.write(ROOT / "README.md", "PROJECT-README.md")
        for file in sorted((ROOT / "docs").rglob("*")):
            if file.is_file():
                z.write(file, file.relative_to(ROOT))
    with archive.open("rb") as f:
        print(archive.name, archive.stat().st_size, "bytes; SHA256:", hashlib.file_digest(f, "sha256").hexdigest())
