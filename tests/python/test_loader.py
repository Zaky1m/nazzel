import hashlib
import json

import pytest
from Cryptodome.PublicKey import ECC
from Cryptodome.Signature import eddsa

import engine
import loader


@pytest.fixture
def signer(monkeypatch):
    key = ECC.generate(curve="ed25519")
    monkeypatch.setattr(loader, "PUBLIC_KEY", key.public_key().export_key(format="PEM"))
    monkeypatch.setattr(loader, "_module", None)
    return eddsa.new(key, "rfc8032")


def install(tmp_path, signer, version, min_build, tamper=False):
    folder = tmp_path / "engine"
    folder.mkdir()
    code = open(engine.__file__, "rb").read().replace(
        f'ENGINE_VERSION = "{engine.ENGINE_VERSION}"'.encode(), f'ENGINE_VERSION = "{version}"'.encode())
    manifest = json.dumps({"version": version, "min_build": min_build,
                           "sha256": hashlib.sha256(code).hexdigest()}).encode()
    (folder / "engine.py").write_bytes(code + (b"#" if tamper else b""))
    (folder / "engine.json").write_bytes(manifest)
    (folder / "engine.json.sig").write_bytes(signer.sign(manifest))


def test_signed_newer_engine_is_used(tmp_path, signer):
    install(tmp_path, signer, "99.0.0", 2)
    assert loader.engine(str(tmp_path), 2).ENGINE_VERSION == "99.0.0"


def test_engine_for_a_newer_app_is_ignored(tmp_path, signer):
    install(tmp_path, signer, "99.0.0", 5)
    assert loader.engine(str(tmp_path), 2) is engine
    assert "newer app" in loader.note()


def test_modified_engine_is_rejected(tmp_path, signer):
    install(tmp_path, signer, "99.0.0", 2, tamper=True)
    assert loader.engine(str(tmp_path), 2) is engine
    assert "hash mismatch" in loader.note()


def test_foreign_signature_is_rejected(tmp_path, signer, monkeypatch):
    install(tmp_path, signer, "99.0.0", 2)
    monkeypatch.setattr(loader, "PUBLIC_KEY", ECC.generate(curve="ed25519").public_key().export_key(format="PEM"))
    assert loader.engine(str(tmp_path), 2) is engine
