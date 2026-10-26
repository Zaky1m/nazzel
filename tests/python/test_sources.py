import io
import json

import engine


def test_multi_video_posts_keep_an_index_per_item():
    data = {"title": "post", "extractor_key": "Twitter",
            "entries": [{"title": "a", "formats": [{}]}, {"title": "b", "formats": [{}]}]}
    payload = engine._playlist_payload("https://x.com/u/status/1", data, engine._Collect())
    assert [i["url"] for i in payload["items"]] == [
        "https://x.com/u/status/1#nazzel-item=1", "https://x.com/u/status/1#nazzel-item=2"]
    assert engine._split_item(payload["items"][1]["url"]) == ("https://x.com/u/status/1", "2")


def test_audio_site_playlists_only_offer_audio():
    data = {"title": "set", "extractor_key": "SoundcloudSet",
            "entries": [{"url": "https://soundcloud.com/a/1"}, {"url": "https://soundcloud.com/a/2"}]}
    payload = engine._playlist_payload("https://soundcloud.com/a/sets/s", data, engine._Collect())
    assert [o["id"] for o in payload["options"]] == ["audio"]


def _embed(entity):
    blob = json.dumps({"props": {"pageProps": {"state": {"data": {"entity": entity}}}}})
    return f'<html><script id="__NEXT_DATA__" type="application/json">{blob}</script></html>'.encode()


class _Response(io.BytesIO):
    def __init__(self, body, url):
        super().__init__(body)
        self._url = url

    def geturl(self):
        return self._url

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


def test_spotify_album_becomes_a_track_list(monkeypatch):
    entity = {"name": "Album", "trackList": [
        {"uri": "spotify:track:AAA", "title": "One", "subtitle": "Singer,\xa0Guest", "duration": 200000},
        {"uri": "spotify:track:BBB", "title": "Two", "subtitle": "Singer", "duration": 100000}]}
    monkeypatch.setattr(engine.urllib.request, "urlopen", lambda req, timeout=0: _Response(_embed(entity), req.full_url))
    out = json.loads(engine.info("https://open.spotify.com/album/XYZ"))
    assert out["type"] == "playlist"
    assert [i["url"] for i in out["items"]] == ["https://open.spotify.com/track/AAA", "https://open.spotify.com/track/BBB"]
    assert out["items"][0]["title"] == "Singer, Guest - One"


def test_spotify_track_searches_youtube_for_artist_and_title(monkeypatch):
    entity = {"name": "Song", "artists": [{"name": "Singer"}], "duration": 213573}
    monkeypatch.setattr(engine.urllib.request, "urlopen", lambda req, timeout=0: _Response(_embed(entity), req.full_url))
    title, query = engine._spotify_query("https://open.spotify.com/track/AAA", engine._Collect())
    assert title == "Singer - Song"
    assert query == "ytsearch1:Singer Song audio"
