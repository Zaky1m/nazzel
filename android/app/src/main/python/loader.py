"""Chooses which engine.py runs: the bundled one, or a newer copy signed with the Nazzel release key.

Signed engine updates fix extraction logic without shipping a new APK. A copy is used only if its
manifest signature verifies, its SHA-256 matches, it is newer than the bundled engine, and it does
not require a newer app build.
"""
import hashlib
import importlib.util
import json
import os
import tempfile
import urllib.request

PUBLIC_KEY = """-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAN+ElQkwY/n3EX9I4Dockw+5az3xW6ahFzylfJXtPRKo=
-----END PUBLIC KEY-----"""
UPDATE_BASE = "https://github.com/Zaky1m/nazzel/releases/latest/download/"
_TIMEOUT = 25
_module = None
_note = "not loaded"


def _verify(manifest, sig):
    from Cryptodome.PublicKey import ECC
    from Cryptodome.Signature import eddsa
    try:
        eddsa.new(ECC.import_key(PUBLIC_KEY), "rfc8032").verify(manifest, sig)
        return True
    except (ValueError, TypeError):
        return False


def _vt(version):
    return tuple(int(x) for x in str(version).split(".") if x.isdigit())


def _read(path):
    with open(path, "rb") as f:
        return f.read()


def _patched(folder, build):
    try:
        manifest = _read(os.path.join(folder, "engine.json"))
        sig = _read(os.path.join(folder, "engine.json.sig"))
        code = _read(os.path.join(folder, "engine.py"))
    except OSError:
        return None, "no update installed"
    if not _verify(manifest, sig):
        return None, "bad signature"
    meta = json.loads(manifest)
    if hashlib.sha256(code).hexdigest() != meta.get("sha256"):
        return None, "hash mismatch"
    if int(meta.get("min_build", 0)) > build:
        return None, "update needs a newer app"
    return meta, "ok"


def engine(data_dir, build, store=False):
    global _module, _note
    if _module is not None:
        return _module
    import engine as bundled
    folder = os.path.join(data_dir, "engine")
    meta, why = (None, "store build") if store else _patched(folder, int(build))
    if meta and _vt(meta["version"]) > _vt(bundled.ENGINE_VERSION):
        try:
            spec = importlib.util.spec_from_file_location("engine_patch", os.path.join(folder, "engine.py"))
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            _module, _note = mod, f"engine {meta['version']} (signed update)"
            return mod
        except Exception as e:  # noqa: BLE001 - a broken update must never stop the app
            why = f"update failed to load: {e}"
    _module, _note = bundled, f"engine {bundled.ENGINE_VERSION} (bundled; {why})"
    return bundled


def note():
    return _note


def _fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "nazzel"})
    with urllib.request.urlopen(req, timeout=_TIMEOUT) as r:
        return r.read()


def _write(folder, name, data):
    fd, tmp = tempfile.mkstemp(dir=folder)
    with os.fdopen(fd, "wb") as f:
        f.write(data)
    os.replace(tmp, os.path.join(folder, name))


def update(data_dir, build):
    """Downloads a newer signed engine; it is used from the next app start. Returns a JSON string."""
    try:
        manifest = _fetch(UPDATE_BASE + "engine.json")
        sig = _fetch(UPDATE_BASE + "engine.json.sig")
        if not _verify(manifest, sig):
            return json.dumps({"ok": False, "message": "bad signature"})
        meta = json.loads(manifest)
        current = getattr(_module, "ENGINE_VERSION", "0")
        if _vt(meta["version"]) <= _vt(current) or int(meta.get("min_build", 0)) > int(build):
            return json.dumps({"ok": True, "updated": False, "version": current})
        code = _fetch(UPDATE_BASE + "engine.py")
        if hashlib.sha256(code).hexdigest() != meta.get("sha256"):
            return json.dumps({"ok": False, "message": "hash mismatch"})
        folder = os.path.join(data_dir, "engine")
        os.makedirs(folder, exist_ok=True)
        # The manifest goes last, so a half-written update never verifies.
        _write(folder, "engine.py", code)
        _write(folder, "engine.json.sig", sig)
        _write(folder, "engine.json", manifest)
        return json.dumps({"ok": True, "updated": True, "version": meta["version"]})
    except Exception as e:  # noqa: BLE001 - reported to the log, never raised into Kotlin
        return json.dumps({"ok": False, "message": f"{type(e).__name__}: {e}"})
