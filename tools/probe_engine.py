"""Runs engine.py outside Android against a real URL. Needs yt-dlp importable (pip install yt-dlp).

Usage: python3.12 tools/probe_engine.py <url> [option_id]
"""
import json
import os
import shutil
import sys
import tempfile

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "android", "app", "src", "main", "python"))
import engine  # noqa: E402

url = sys.argv[1]
work = tempfile.mkdtemp(prefix="nazzel-probe-")
try:
    print("configure:", engine.configure(work))
    meta = json.loads(engine.info(url))
    print("info:", json.dumps(meta, ensure_ascii=False, indent=1)[:900])
    if meta.get("ok"):
        option = sys.argv[2] if len(sys.argv) > 2 else meta["options"][0]["id"]
        seen = []

        def cb(percent, speed):
            if not seen or percent - seen[-1] >= 25:
                seen.append(percent)
            return False

        out = json.loads(engine.download(url, option, os.path.join(work, "out"), cb))
        print("download:", out, "progress samples:", [round(p) for p in seen])
        for f in out.get("files", []):
            print(" ", os.path.basename(f), os.path.getsize(f), "bytes")
finally:
    shutil.rmtree(work, ignore_errors=True)
