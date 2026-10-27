class QualityOption {
  const QualityOption({required this.id, required this.kind, required this.quality, required this.label, this.size});

  final String id;
  final String kind;
  final int quality;
  final String label;
  final int? size;

  bool get isAudio => kind == 'audio';

  factory QualityOption.fromJson(Map<String, dynamic> j) => QualityOption(
    id: j['id'] as String,
    kind: j['kind'] as String,
    quality: (j['quality'] as num?)?.toInt() ?? 0,
    label: j['label'] as String,
    size: (j['size'] as num?)?.toInt(),
  );
}

class PlaylistItem {
  const PlaylistItem({required this.url, required this.title, this.duration, this.thumbnail});

  final String url;
  final String title;
  final double? duration;
  final String? thumbnail;

  factory PlaylistItem.fromJson(Map<String, dynamic> j) => PlaylistItem(
    url: j['url'] as String,
    title: j['title'] as String? ?? '',
    duration: (j['duration'] as num?)?.toDouble(),
    thumbnail: j['thumbnail'] as String?,
  );
}

class VideoInfo {
  const VideoInfo({
    required this.url,
    required this.title,
    required this.thumbnail,
    required this.duration,
    required this.site,
    required this.options,
    this.items = const [],
  });

  final String url;
  final String title;
  final String? thumbnail;
  final double? duration;
  final String? site;
  final List<QualityOption> options;
  final List<PlaylistItem> items;

  bool get isPlaylist => items.isNotEmpty;

  factory VideoInfo.fromJson(String url, Map<String, dynamic> j) => VideoInfo(
    url: url,
    title: j['title'] as String? ?? '',
    thumbnail: j['thumbnail'] as String?,
    duration: (j['duration'] as num?)?.toDouble(),
    site: j['site'] as String?,
    options: (j['options'] as List).map((o) => QualityOption.fromJson(o as Map<String, dynamic>)).toList(),
    items: (j['items'] as List? ?? const []).map((e) => PlaylistItem.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class DownloadItem {
  const DownloadItem({
    required this.id,
    required this.title,
    required this.thumb,
    required this.status,
    required this.percent,
    required this.speed,
    required this.mime,
    required this.error,
    required this.detail,
    required this.optionId,
    required this.batchId,
    required this.batchTitle,
    required this.createdAt,
  });

  final String id, title, status, optionId;
  final String? thumb, mime, error, detail, batchId, batchTitle;
  final int createdAt;
  final double percent, speed;

  bool get isRunning => status == 'running' || status == 'queued';
  bool get isDone => status == 'done';
  bool get isFailed => status == 'failed' || status == 'canceled';

  factory DownloadItem.fromJson(Map<String, dynamic> j) => DownloadItem(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    thumb: j['thumb'] as String?,
    status: j['status'] as String,
    percent: (j['percent'] as num?)?.toDouble() ?? 0,
    speed: (j['speed'] as num?)?.toDouble() ?? 0,
    mime: j['mime'] as String?,
    error: j['error'] as String?,
    detail: j['detail'] as String?,
    optionId: j['optionId'] as String? ?? '',
    batchId: j['batchId'] as String?,
    batchTitle: j['batchTitle'] as String?,
    createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
  );
}

class EngineFailure implements Exception {
  const EngineFailure(this.code, [this.message = '']);
  final String code;
  final String message;
}
