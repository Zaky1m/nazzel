import json

import pytest

import engine


@pytest.fixture
def store_mode(monkeypatch):
    monkeypatch.setattr(engine, "_store", True)


@pytest.mark.parametrize("url", [
    "https://www.youtube.com/watch?v=abc",
    "https://youtu.be/abc",
])
def test_store_build_refuses_blocked_sites(store_mode, url):
    out = json.loads(engine.info(url))
    assert out["ok"] is False and out["code"] == "unsupported"


def test_other_sites_pass_the_store_check(store_mode):
    engine._check_allowed("https://vimeo.com/1")


def test_store_build_does_not_update_the_downloader(store_mode):
    out = json.loads(engine.update())
    assert out["ok"] is False


def test_unsupported_url_message_wins_over_unavailable_wording():
    assert engine._classify("ERROR: Unsupported URL: https://example.com/this-video-is-not-available") == "unsupported"


def test_unknown_sites_are_not_fetched():
    assert engine._opts()["allowed_extractors"] == ["default", "-generic"]


def test_link_without_an_extractor_is_unsupported():
    assert engine._classify("DownloadError: ERROR: No suitable extractor found for URL https://example.com/page") == "unsupported"


@pytest.mark.parametrize("url", ["https://open.spotify.com/track/1", "https://spotify.link/x", "ytsearch1:anything"])
def test_spotify_and_search_links_are_refused_in_every_build(url):
    out = json.loads(engine.info(url))
    assert out["ok"] is False and out["code"] == "unsupported"
