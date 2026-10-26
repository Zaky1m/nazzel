"""yt-dlp wrapper used by the Android app through Chaquopy.

Every public function returns a JSON string and never raises, so the Kotlin side only has
to parse one shape: {"ok": true, ...} or {"ok": false, "code": ..., "message": ...}.
"""
import hashlib
import importlib
import json
import os
import re
import sys
import tempfile
import time
import traceback
import urllib.request

# Bumped whenever engine.py changes; signed engine updates only apply when newer than this.
ENGINE_VERSION = "1.2.0"

_RELEASES = "https://github.com/yt-dlp/yt-dlp/releases"
_API_LATEST = "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest"
_TIMEOUT = 25
_data_dir = None
_qjs_path = None


class _Cancelled(Exception):
    pass


class EngineError(Exception):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = code
        self.message = message


def configure(data_dir, qjs_path=None):
    """Puts a previously downloaded yt-dlp in front of the bundled one and records the QuickJS binary."""
    global _data_dir, _qjs_path
    _data_dir = data_dir
    _qjs_path = qjs_path if qjs_path and os.access(qjs_path, os.X_OK) else None
    path = _updated_path()
    if path and os.path.isfile(path) and path not in sys.path:
        sys.path.insert(0, path)
    return json.dumps({"ok": True, "version": _version()})


def _updated_path():
    return os.path.join(_data_dir, "ytdlp", "yt-dlp") if _data_dir else None


def _ytdlp():
    import yt_dlp
    return yt_dlp


def _version():
    return _ytdlp().version.__version__


def _classify(message):
    low = message.lower()
    if any(k in low for k in ("registered users", "log in", "login", "sign in", "private", "not available", "unavailable", "removed", "age-restricted", "confirm your age")):
        return "private"
    if any(k in low for k in ("not found", "http error 404", "does not exist", "deleted", "no longer available")):
        return "missing"
    if "unsupported url" in low:
        return "unsupported"
    if any(k in low for k in ("urlopen", "timed out", "temporary failure", "connection", "network", "name resolution")):
        return "network"
    if any(k in low for k in ("cannot parse", "unable to extract", "unable to download webpage", "no video formats")):
        return "extractor"
    return "unknown"


def _safe(fn):
    def wrapper(*args, **kwargs):
        try:
            return json.dumps(fn(*args, **kwargs), ensure_ascii=False)
        except _Cancelled:
            return json.dumps({"ok": False, "code": "canceled", "message": "canceled"})
        except EngineError as e:
            return json.dumps({"ok": False, "code": e.code, "message": e.message})
        except Exception as e:  # noqa: BLE001 - last resort so Kotlin always gets JSON
            msg = str(e)
            return json.dumps({"ok": False, "code": _classify(msg), "message": msg[:300]})
    return wrapper


class _Collect:
    """yt-dlp logger that keeps its output so the app can show it when something fails on a real phone."""
    MAX_LINES = 500
    MAX_LINE = 400

    def __init__(self):
        self.lines = []
        self._t0 = time.time()
        self.check = None

    def add(self, level, msg):
        # yt-dlp logs at every network step, so this is where a cancel gets noticed before any byte is downloaded.
        if self.check and self.check():
            raise _Cancelled()
        if len(self.lines) >= self.MAX_LINES:
            if len(self.lines) == self.MAX_LINES:
                self.lines.append("... output truncated")
            return
        for part in str(msg).splitlines() or [""]:
            self.lines.append(f"+{time.time() - self._t0:6.1f}s {level}: {part[:self.MAX_LINE]}")

    def debug(self, msg):
        self.add("debug", msg)

    def info(self, msg):
        self.add("info", msg)

    def warning(self, msg):
        self.add("warn", msg)

    def error(self, msg):
        self.add("error", msg)


def _logged(always):
    """Like _safe, but hands the function a collector and always returns what it collected on failure."""
    def deco(fn):
        def wrapper(*args):
            lg = _Collect()
            try:
                out = fn(*args, lg=lg)
                if always:
                    out["log"] = lg.lines
                return json.dumps(out, ensure_ascii=False)
            except _Cancelled:
                out = {"ok": False, "code": "canceled", "message": "canceled"}
            except EngineError as e:
                out = {"ok": False, "code": e.code, "message": e.message}
            except Exception as e:  # noqa: BLE001 - last resort so Kotlin always gets JSON
                lg.add("traceback", traceback.format_exc())
                out = {"ok": False, "code": _classify(str(e)), "message": f"{type(e).__name__}: {str(e)[:300]}"}
            out["log"] = lg.lines
            return json.dumps(out, ensure_ascii=False)
        return wrapper
    return deco


def _single(info):
    if info.get("_type") == "playlist":
        entries = [e for e in (info.get("entries") or []) if e]
        if not entries:
            raise EngineError("unsupported", "empty playlist")
        return entries[0]
    return info


_MUX_EXT = ("mp4", "m4v", "mov")
_AUDIO_EXT = ("m4a", "mp3", "aac", "opus", "ogg", "oga", "flac", "wav", "weba")
# Order of preference for "audio only": formats phones play everywhere first.
_AUDIO_PREF = {"m4a": 3, "mp3": 2, "aac": 2}


def _is_audio(f):
    return f.get("vcodec") == "none" or (f.get("vcodec") is None and f.get("ext") in _AUDIO_EXT)


def _quality(f):
    # Vertical videos report the long side as height, so the short side is what viewers call "720p".
    h, w = f.get("height"), f.get("width")
    return min(h, w) if h and w else (h or 0)


def _size(*fmts):
    total = sum((f.get("filesize") or f.get("filesize_approx") or 0) for f in fmts if f)
    return total or None


def _muxable(f):
    # MediaMuxer on API 29 can put H.264/HEVC in an MP4, but not AV1 or VP9.
    codec = str(f.get("vcodec") or "")
    return f.get("ext") in _MUX_EXT and not codec.startswith(("av01", "vp9", "vp09"))


def _abr(f):
    return f.get("abr") or f.get("tbr") or 0


def _choices(formats):
    """Quality options the phone can finish: single files, or mp4 video + m4a audio it can remux."""
    formats = [f for f in formats if f.get("format_id") and f.get("ext") != "mhtml"]
    audios = [f for f in formats if _is_audio(f) and f.get("acodec") != "none"]
    videos = [f for f in formats if not _is_audio(f)]
    mux_audio = max((f for f in audios if f.get("ext") == "m4a"), key=_abr, default=None)
    best_audio = max(audios, key=lambda f: (_AUDIO_PREF.get(f.get("ext"), 1), _abr(f)), default=None)
    usable = [f for f in videos if _muxable(f) and (f.get("acodec") != "none" or mux_audio)]
    pool = usable or [f for f in videos if f.get("acodec") != "none"]
    choices = []
    by_quality = {}
    for f in pool:
        q = _quality(f)
        if q and (q not in by_quality or (f.get("tbr") or 0) > (by_quality[q].get("tbr") or 0)):
            by_quality[q] = f
    for q in sorted(by_quality, reverse=True)[:5]:
        v = by_quality[q]
        a = mux_audio if v.get("acodec") == "none" else None
        choices.append({"id": f"q{q}", "kind": "video", "quality": q, "label": f"{q}p", "video": v, "audio": a})
    if not choices:
        for f in sorted(pool, key=lambda f: f.get("tbr") or f.get("quality") or 0, reverse=True)[:3]:
            choices.append({"id": f"f{f['format_id']}", "kind": "video", "quality": 0,
                            "label": str(f["format_id"]).upper(), "video": f, "audio": None})
    if best_audio:
        choices.append({"id": "audio", "kind": "audio", "quality": 0, "label": "audio", "video": None, "audio": best_audio})
    return choices


def _options(formats):
    return [{"id": c["id"], "kind": c["kind"], "quality": c["quality"], "label": c["label"],
             "size": _size(c["video"], c["audio"])} for c in _choices(formats)]


def _pick(option_id, choices):
    """Exact option, or for playlists (where options are generic) the closest one not above the request."""
    videos = [c for c in choices if c["kind"] == "video"]
    if option_id == "audio":
        return next((c for c in choices if c["kind"] == "audio"), videos[-1] if videos else None)
    exact = next((c for c in choices if c["id"] == option_id), None)
    if exact or not videos:
        return exact
    if option_id.startswith("q") and option_id[1:].isdigit():
        limit = int(option_id[1:])
        return next((c for c in videos if c["quality"] and c["quality"] <= limit), videos[-1])
    return videos[0]


def _selector(option_id, formats):
    choice = _pick(option_id, _choices(formats))
    if not choice:
        return "ba/b" if option_id == "audio" else "b"
    ids = [f["format_id"] for f in (choice["video"], choice["audio"]) if f]
    return "+".join(ids) + "/b"


def _opts(extra=None, lg=None):
    opts = {
        "quiet": True,
        "no_warnings": True,
        "noplaylist": True,
        "socket_timeout": _TIMEOUT,
        "retries": 3,
        "restrictfilenames": True,
        "nopart": False,
        "noprogress": True,
    }
    if _qjs_path:
        # YouTube's signature and n-parameter challenges are solved by yt-dlp-ejs running inside QuickJS.
        opts["js_runtimes"] = {"quickjs": {"path": _qjs_path}}
    if lg is not None:
        opts.update({"logger": lg, "verbose": True})
    opts.update(extra or {})
    return opts


_MAX_ITEMS = 200
# Generic options for a whole playlist; each item later resolves to its nearest real format.
_PLAYLIST_OPTIONS = [
    {"id": "best", "kind": "video", "quality": 0, "label": "best", "size": None},
    {"id": "q1080", "kind": "video", "quality": 1080, "label": "1080p", "size": None},
    {"id": "q720", "kind": "video", "quality": 720, "label": "720p", "size": None},
    {"id": "q480", "kind": "video", "quality": 480, "label": "480p", "size": None},
    {"id": "audio", "kind": "audio", "quality": 0, "label": "audio", "size": None},
]
_ITEM_MARK = "#nazzel-item="
_AUDIO_SITES = ("soundcloud", "bandcamp", "mixcloud", "audiomack", "spotify")


def _split_item(url):
    """Items of multi-video posts have no URL of their own, so they travel as post URL + index."""
    if _ITEM_MARK in url:
        base, idx = url.split(_ITEM_MARK, 1)
        return base, idx
    return url, None


def _thumb(entry):
    if entry.get("thumbnail"):
        return entry["thumbnail"]
    thumbs = entry.get("thumbnails") or []
    return thumbs[-1].get("url") if thumbs else None


def _playlist_payload(url, data, lg):
    entries = [e for e in (data.get("entries") or []) if e][:_MAX_ITEMS]
    items = []
    for i, e in enumerate(entries, 1):
        item_url = e.get("webpage_url") or (e.get("url") if str(e.get("url", "")).startswith("http") else None)
        if not item_url or e.get("formats"):
            item_url = f"{url}{_ITEM_MARK}{i}"
        items.append({"url": item_url, "title": e.get("title") or f"{i}", "duration": e.get("duration"),
                      "thumbnail": _thumb(e)})
    lg.add("playlist", f"{len(items)} items")
    return {
        "ok": True, "type": "playlist", "title": data.get("title") or data.get("id") or "",
        "site": data.get("extractor_key"), "thumbnail": _thumb(data) or (items[0]["thumbnail"] if items else None),
        "items": items,
        "options": [o for o in _PLAYLIST_OPTIONS if o["kind"] == "audio"]
        if str(data.get("extractor_key", "")).lower().startswith(_AUDIO_SITES) else _PLAYLIST_OPTIONS,
    }


@_logged(always=False)
def info(url, lg):
    if _is_spotify(url):
        return _spotify_info(url, lg)
    base, item = _split_item(url)
    yt_dlp = _ytdlp()
    extra = {"skip_download": True, "extract_flat": "in_playlist"}
    if item:
        extra.update({"noplaylist": False, "playlist_items": item})
    with yt_dlp.YoutubeDL(_opts(extra, lg)) as ydl:
        data = ydl.extract_info(base, download=False)
    if data.get("_type") == "playlist" and not item:
        entries = [e for e in (data.get("entries") or []) if e]
        if len(entries) > 1:
            return _playlist_payload(base, data, lg)
    data = _single(data)
    formats = data.get("formats") or []
    options = _options(formats)
    lg.add("options", json.dumps([(o["id"], o["label"], o["size"]) for o in options]))
    if not options:
        raise EngineError("extractor", "no downloadable formats")
    return {
        "ok": True,
        "type": "single",
        "title": data.get("title") or data.get("id") or "",
        "thumbnail": _thumb(data),
        "duration": data.get("duration"),
        "uploader": data.get("uploader") or data.get("extractor_key"),
        "site": data.get("extractor_key"),
        "options": options,
    }


# ---------- Spotify: tracks are DRM-protected, so names come from the public embed page and the
# audio from the first YouTube search result for "artist - title".
_SPOTIFY = re.compile(r"open\.spotify\.com/(?:intl-[a-z]+/)?(track|album|playlist)/([A-Za-z0-9]+)")
_UA = "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0 Mobile Safari/537.36"


def _is_spotify(url):
    return "spotify.com/" in url or "spotify.link/" in url


def _spotify_entity(url):
    if "spotify.link/" in url:
        req = urllib.request.Request(url, headers={"User-Agent": _UA})
        with urllib.request.urlopen(req, timeout=_TIMEOUT) as r:
            url = r.geturl()
    m = _SPOTIFY.search(url)
    if not m:
        raise EngineError("unsupported", "unsupported Spotify link")
    kind, sid = m.groups()
    req = urllib.request.Request(f"https://open.spotify.com/embed/{kind}/{sid}", headers={"User-Agent": _UA})
    with urllib.request.urlopen(req, timeout=_TIMEOUT) as r:
        html = r.read().decode("utf-8", "replace")
    found = re.search(r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>', html, re.S)
    if not found:
        raise EngineError("extractor", "Spotify page changed")
    entity = json.loads(found.group(1))["props"]["pageProps"]["state"]["data"]["entity"]
    return kind, sid, entity


def _spotify_image(entity):
    images = (entity.get("visualIdentity") or {}).get("image") or (entity.get("coverArt") or {}).get("sources") or []
    return max(images, key=lambda i: i.get("maxWidth") or 0).get("url") if images else None


def _spotify_info(url, lg):
    kind, sid, entity = _spotify_entity(url)
    lg.add("spotify", f"{kind} {sid} {entity.get('name')}")
    audio_only = [{"id": "audio", "kind": "audio", "quality": 0, "label": "audio", "size": None}]
    if kind == "track":
        artists = ", ".join(a.get("name", "") for a in entity.get("artists") or [])
        return {
            "ok": True, "type": "single", "title": f"{artists} - {entity.get('name')}".strip(" -"),
            "thumbnail": _spotify_image(entity), "duration": (entity.get("duration") or 0) / 1000 or None,
            "uploader": artists, "site": "Spotify", "options": audio_only,
        }
    items = []
    for t in (entity.get("trackList") or [])[:_MAX_ITEMS]:
        tid = str(t.get("uri", "")).rsplit(":", 1)[-1]
        if not tid:
            continue
        artists = str(t.get("subtitle") or "").replace("\xa0", " ")
        items.append({"url": f"https://open.spotify.com/track/{tid}", "title": f"{artists} - {t.get('title')}".strip(" -"),
                      "duration": (t.get("duration") or 0) / 1000 or None, "thumbnail": None})
    return {"ok": True, "type": "playlist", "title": entity.get("name") or "", "site": "Spotify",
            "thumbnail": _spotify_image(entity), "items": items, "options": audio_only}


def _spotify_query(url, lg):
    kind, sid, entity = _spotify_entity(url)
    if kind != "track":
        raise EngineError("unsupported", "open the album or playlist to pick its tracks")
    artists = " ".join(a.get("name", "") for a in entity.get("artists") or [])
    title = f"{artists} - {entity.get('name')}".strip(" -")
    lg.add("spotify", f"searching YouTube for: {title}")
    return title, f"ytsearch1:{artists} {entity.get('name')} audio"


# YouTube serves some clients URLs that answer 403 without a proof-of-origin token or a JS runtime,
# neither of which exists on a phone, so other clients are tried in turn when that happens.
_YT_CLIENTS = ("android_vr", "tv", "ios", "mweb")


def _is_youtube(url):
    return any(h in url for h in ("youtube.com", "youtu.be"))


@_logged(always=True)
def download(url, option_id, out_dir, progress_cb, lg):
    """progress_cb(percent: float, speed: float|None) -> bool. Returning True cancels."""
    yt_dlp = _ytdlp()
    report = getattr(progress_cb, "onProgress", progress_cb)
    lg.check = lambda: report(-1.0, 0.0)
    title_override = None
    if _is_spotify(url):
        title_override, url = _spotify_query(url, lg)
        option_id = "audio"
    base, item = _split_item(url)
    clients = (None,) + (_YT_CLIENTS if _is_youtube(base) or base.startswith("ytsearch") else ())
    last = None
    for client in clients:
        extra = {"extractor_args": {"youtube": {"player_client": [client]}}} if client else {}
        if item:
            extra.update({"noplaylist": False, "playlist_items": item})
        lg.add("phase", f"extract {base} item={item} option={option_id} client={client or 'default'}")
        try:
            with yt_dlp.YoutubeDL(_opts({"skip_download": True, **extra}, lg)) as probe:
                data = _single(probe.extract_info(base, download=False))
            if title_override:
                data["title"] = title_override
            return _download_info(data, option_id, out_dir, progress_cb, lg, extra)
        except (_Cancelled, EngineError):
            raise
        except Exception as e:  # noqa: BLE001 - only 403 moves on to the next client
            lg.add("attempt", f"client={client or 'default'} failed: {str(e)[:250]}")
            if "403" not in str(e) and "forbidden" not in str(e).lower():
                raise
            last = e
    raise last


def _download_info(data, option_id, out_dir, progress_cb, lg, extra=None):
    yt_dlp = _ytdlp()
    os.makedirs(out_dir, exist_ok=True)
    state = {}
    expected = [0]
    # Chaquopy hands over a Kotlin object exposing onProgress; the probe script passes a plain function.
    report = getattr(progress_cb, "onProgress", progress_cb)

    def hook(d):
        if d.get("status") not in ("downloading", "finished"):
            return
        key = d.get("filename") or d.get("tmpfilename") or ""
        state[key] = (d.get("downloaded_bytes") or 0,
                      d.get("total_bytes") or d.get("total_bytes_estimate") or 0)
        grand = max(sum(v[1] for v in state.values()), expected[0])
        percent = min(99.0, 100.0 * sum(v[0] for v in state.values()) / grand) if grand else 0.0
        if report(float(percent), float(d.get("speed") or 0.0)):
            raise _Cancelled()

    selector = _selector(option_id, data.get("formats") or [])
    lg.add("phase", f"selector={selector}")
    extra = {k: v for k, v in (extra or {}).items() if k not in ("playlist_items", "noplaylist")}
    with yt_dlp.YoutubeDL(_opts({"format": selector, "skip_download": True, **extra}, lg)) as ydl:
        picks = ydl.process_ie_result(dict(data), download=False).get("requested_formats") or [None]
    expected[0] = sum((f.get("filesize") or f.get("filesize_approx") or 0) for f in picks if f)
    lg.add("phase", f"streams={[(f or {}).get('format_id') for f in picks]} expected_bytes={expected[0]}")

    # yt-dlp refuses to merge without ffmpeg, so each stream is fetched on its own and Kotlin
    # muxes video + audio with MediaMuxer. The video stream always comes first.
    files = []
    for pick in picks:
        fmt = pick["format_id"] if pick else selector
        suffix = f".f{pick['format_id']}" if pick and len(picks) > 1 else ""
        lg.add("phase", f"download stream {fmt}")
        opts = _opts({
            "format": fmt,
            "outtmpl": os.path.join(out_dir, "%(extractor)s_%(id).60B" + suffix + ".%(ext)s"),
            "progress_hooks": [hook],
            "overwrites": True,
            **extra,
        }, lg)
        with yt_dlp.YoutubeDL(opts) as ydl:
            result = ydl.process_ie_result(dict(data), download=True)
        got = [d["filepath"] for d in (result.get("requested_downloads") or [])
               if d.get("filepath") and os.path.isfile(d["filepath"])]
        lg.add("phase", f"stream {fmt} files={[(os.path.basename(f), os.path.getsize(f)) for f in got]}")
        files += got
    if not files:
        raise EngineError("unknown", "no output file")
    return {
        "ok": True,
        "files": files,
        "title": data.get("title") or "",
        "audio_only": option_id == "audio" or not any(f.get("vcodec") not in (None, "none") for f in picks if f)
        and all(_is_audio(f) for f in picks if f) and any(picks),
    }


def _fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "nazzel"})
    with urllib.request.urlopen(req, timeout=_TIMEOUT) as r:
        return r.read()


@_safe
def update():
    """Downloads the latest yt-dlp zipapp, verifies its SHA-256, and activates it."""
    if not _data_dir:
        raise EngineError("unknown", "engine not configured")
    current = _version()
    latest = json.loads(_fetch(_API_LATEST))["tag_name"]
    if latest == current:
        return {"ok": True, "version": current, "updated": False}
    blob = _fetch(f"{_RELEASES}/download/{latest}/yt-dlp")
    sums = _fetch(f"{_RELEASES}/download/{latest}/SHA2-256SUMS").decode()
    expected = next((l.split()[0] for l in sums.splitlines() if l.strip().endswith(" yt-dlp") or l.strip().endswith("*yt-dlp")), None)
    if not expected or hashlib.sha256(blob).hexdigest() != expected:
        raise EngineError("network", "checksum mismatch")
    target = _updated_path()
    os.makedirs(os.path.dirname(target), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(target))
    with os.fdopen(fd, "wb") as f:
        f.write(blob)
    os.replace(tmp, target)
    if target in sys.path:
        sys.path.remove(target)
    sys.path.insert(0, target)
    for name in [m for m in sys.modules if m == "yt_dlp" or m.startswith("yt_dlp.")]:
        del sys.modules[name]
    importlib.invalidate_caches()
    return {"ok": True, "version": _version(), "updated": True}


@_safe
def version():
    return {"ok": True, "version": _version(), "engine": ENGINE_VERSION}
