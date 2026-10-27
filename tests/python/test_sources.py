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
