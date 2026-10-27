import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';

/// Thin typed wrapper over the native channel. All download state lives in the native SQLite store.
class EngineApi {
  EngineApi._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') changes.value++;
      if (call.method == 'clipboardUrl') _clipboard.add(call.arguments as String);
    });
  }

  static final EngineApi instance = EngineApi._();

  final MethodChannel _channel = const MethodChannel('app.nazzel/engine');

  final StreamController<String> _clipboard = StreamController<String>.broadcast();

  /// Links found in a fresh clipboard when the app gains focus.
  Stream<String> get onClipboardUrl => _clipboard.stream;

  /// Bumped whenever native code reports a change to any download row.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<VideoInfo> info(String url) async {
    final raw = await _channel.invokeMethod<String>('info', {'url': url});
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    if (json['ok'] != true) throw EngineFailure(json['code'] as String? ?? 'unknown', json['message'] as String? ?? '');
    return VideoInfo.fromJson(url, json);
  }

  Future<void> enqueue(VideoInfo info, QualityOption option) => _channel.invokeMethod('enqueue', {
    'url': info.url,
    'title': info.title,
    'thumb': info.thumbnail,
    'optionId': option.id,
  });

  Future<void> enqueueBatch(VideoInfo info, List<PlaylistItem> items, QualityOption option) =>
      _channel.invokeMethod('enqueueBatch', {
        'title': info.title,
        'optionId': option.id,
        'items': [
          for (final i in items) {'url': i.url, 'title': i.title, 'thumb': i.thumbnail},
        ],
      });

  Future<void> cancelBatch(String batchId) => _channel.invokeMethod('cancelBatch', {'batchId': batchId});

  Future<Map<String, dynamic>> stats() async =>
      jsonDecode(await _channel.invokeMethod<String>('stats') ?? '{}') as Map<String, dynamic>;

  Future<Map<String, dynamic>> appInfo() async =>
      jsonDecode(await _channel.invokeMethod<String>('appInfo') ?? '{}') as Map<String, dynamic>;

  Future<Map<String, dynamic>?> updateInfo({bool refresh = false}) async {
    final raw = await _channel.invokeMethod<String>('updateInfo', {'refresh': refresh});
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<List<DownloadItem>> list() async {
    final raw = await _channel.invokeMethod<String>('list');
    return (jsonDecode(raw!) as List).map((e) => DownloadItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> cancel(String id) => _channel.invokeMethod('cancel', {'id': id});
  Future<void> retry(String id) => _channel.invokeMethod('retry', {'id': id});
  Future<void> delete(String id) => _channel.invokeMethod('delete', {'id': id});
  Future<void> deleteMany(List<String> ids) => _channel.invokeMethod('deleteMany', {'ids': ids});
  Future<bool> openLink(String url) async => await _channel.invokeMethod<bool>('openLink', {'url': url}) ?? false;
  Future<String> saveLocation() async => await _channel.invokeMethod<String>('saveLocation') ?? '';

  /// Opens the system folder picker; returns the new location label, or null when the user backs out.
  Future<String?> pickFolder() => _channel.invokeMethod<String>('pickFolder');
  Future<String> resetSaveLocation() async => await _channel.invokeMethod<String>('resetSaveLocation') ?? '';
  Future<bool> open(String id) async => await _channel.invokeMethod<bool>('open', {'id': id}) ?? false;
  Future<bool> share(String id) async => await _channel.invokeMethod<bool>('share', {'id': id}) ?? false;
  Future<void> closeShare() => _channel.invokeMethod('closeShare');
  Future<String?> sharedUrl() => _channel.invokeMethod<String>('sharedUrl');
  Future<String?> getPref(String key) => _channel.invokeMethod<String>('getPref', {'key': key});
  Future<void> setPref(String key, String value) => _channel.invokeMethod('setPref', {'key': key, 'value': value});
  Future<void> askNotifications() => _channel.invokeMethod('askNotifications');
}
