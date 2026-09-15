from pathlib import Path
import hashlib, json, sys, zipfile

def verify(assets, archive=None):
    manifest = json.loads((assets / "image-manifest.json").read_text())
    errors = []
    if len(manifest) != 72:
        errors.append(f"MANIFEST COUNT: expected 72, found {len(manifest)}")
    for name, expected in manifest.items():
        if not name.startswith("media/") or ".." in Path(name).parts:
            errors.append(f"INVALID PATH: {name}")
            continue
        try:
            data = archive.read("assets/" + name) if archive else (assets / name).read_bytes()
        except (OSError, KeyError):
            errors.append(f"MISSING: {name}")
            continue
        if not data.startswith(b"\x89PNG\r\n\x1a\n"):
            errors.append(f"NOT PNG: {name}")
        elif hashlib.sha256(data).hexdigest() != expected:
            errors.append(f"HASH MISMATCH: {name}")
    for error in errors:
        print(error)
    if errors:
        print(f"FAIL: {len(errors)} issues. Replace only the listed files using the matching V18.9 assets.")
        return 1
    print(f"PASS: {len(manifest)} images verified in " + ("APK" if archive else "source"))
    return 0

if __name__ == "__main__":
    assets = Path(__file__).resolve().parents[1] / "app/src/main/assets"
    if len(sys.argv) > 1:
        with zipfile.ZipFile(sys.argv[1]) as archive:
            sys.exit(verify(assets, archive))
    sys.exit(verify(assets))
