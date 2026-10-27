import engine

YOUTUBE_SHORT = [
    {"format_id": "137", "ext": "mp4", "vcodec": "avc1.640028", "acodec": "none", "width": 1080, "height": 1920, "tbr": 3000},
    {"format_id": "136", "ext": "mp4", "vcodec": "avc1.4d401f", "acodec": "none", "width": 720, "height": 1280, "tbr": 1500},
    {"format_id": "313", "ext": "webm", "vcodec": "vp9", "acodec": "none", "width": 2160, "height": 3840, "tbr": 9000},
    {"format_id": "401", "ext": "mp4", "vcodec": "av01.0.12M.08", "acodec": "none", "width": 2160, "height": 3840, "tbr": 8000},
    {"format_id": "140", "ext": "m4a", "vcodec": "none", "acodec": "mp4a.40.2", "abr": 128},
    {"format_id": "251", "ext": "webm", "vcodec": "none", "acodec": "opus", "abr": 160},
]
FACEBOOK_PROGRESSIVE = [
    {"format_id": "sd", "ext": "mp4", "vcodec": None, "acodec": None, "tbr": 500},
    {"format_id": "hd", "ext": "mp4", "vcodec": None, "acodec": None, "tbr": 1200},
]
SOUNDCLOUD = [
    {"format_id": "hls_opus", "ext": "opus", "vcodec": "none", "acodec": "opus", "abr": 64},
    {"format_id": "http_mp3", "ext": "mp3", "vcodec": "none", "acodec": "mp3", "abr": 128},
]


def ids(formats):
    return [o["id"] for o in engine._options(formats)]


def test_vertical_video_is_labelled_by_its_short_side():
    assert ids(YOUTUBE_SHORT) == ["q1080", "q720", "audio"]


def test_codecs_mediamuxer_cannot_handle_are_skipped():
    assert "q2160" not in ids(YOUTUBE_SHORT)


def test_video_only_streams_are_paired_with_m4a_audio():
    assert engine._selector("q720", YOUTUBE_SHORT) == "136+140/b"


def test_progressive_files_without_resolution_use_their_ids():
    assert ids(FACEBOOK_PROGRESSIVE) == ["fhd", "fsd"]
    assert engine._selector("best", FACEBOOK_PROGRESSIVE) == "hd/b"


def test_audio_only_sites_offer_one_audio_choice():
    assert ids(SOUNDCLOUD) == ["audio"]
    assert engine._selector("audio", SOUNDCLOUD) == "http_mp3/b"


def test_playlist_options_resolve_to_the_nearest_lower_quality():
    assert engine._selector("q900", YOUTUBE_SHORT) == "136+140/b"
    assert engine._selector("q100", YOUTUBE_SHORT) == "136+140/b"


def test_error_messages_map_to_codes():
    assert engine._classify("ERROR: This video is only available for registered users") == "private"
    assert engine._classify("ERROR: [dailymotion] x: Not found.") == "missing"
    assert engine._classify("ERROR: Unsupported URL: https://example.com") == "unsupported"
    assert engine._classify("Cannot parse data") == "extractor"


def test_formats_without_a_picture_size_are_named_by_rank():
    formats = [
        {"format_id": "1", "ext": "mp4", "vcodec": "avc1", "acodec": "mp4a", "tbr": 900},
        {"format_id": "2", "ext": "mp4", "vcodec": "avc1", "acodec": "mp4a", "tbr": 1800},
        {"format_id": "3", "ext": "mp4", "vcodec": "avc1", "acodec": "mp4a", "tbr": 400},
    ]
    options = engine._options(formats)
    assert [(o["id"], o["label"]) for o in options] == [("f2", "tier1"), ("f1", "tier2"), ("f3", "tier3")]


def test_size_is_read_from_text_when_the_site_gives_no_numbers():
    assert engine._quality({"format_id": "hls-720p"}) == 720
    assert engine._quality({"resolution": "1280x720"}) == 720
    assert engine._quality({"format_note": "480p"}) == 480
    assert engine._quality({"format_id": "1"}) == 0
    assert engine._quality({"format_id": "3000k"}) == 0
