import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Downloader for the Quran JSON assets.
///
/// Usage:
///   await QuranDownloader.ensureInitialized();
///   final data = await QuranDownloader.loadJson('en.json');
abstract final class QuranDownloader {
  // ================  public API  ================
  static   String _root='';

  /// Idempotent initialiser – safe to call many times.
  static Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await _initOnce;
  }

  /// Reads a previously downloaded JSON file.
  static Future<dynamic> loadJson(String filename) async {
    final file = File(p.join(_root, filename));
    if (!file.existsSync()) {
      throw StateError(
          '"$filename" not found. Call QuranDownloader.ensureInitialized() first.');
    }
    return jsonDecode(await file.readAsString());
  }

  // ================  private  ================
  static const _kFolder = 'quran_data';
  static const _kAssets = {
    'en.json': 'https://cdn.jsdelivr.net/gh/yousef-nageh/quran_library@main/assets/jsons/en.json.gz',
    'quranV3.json': 'https://cdn.jsdelivr.net/gh/yousef-nageh/quran_library@main/assets/jsons/quranV3.json.gz',
    'quran_hafs.json': 'https://cdn.jsdelivr.net/gh/yousef-nageh/quran_library@main/assets/jsons/quran_hafs.json.gz',
    'saadi.json': 'https://cdn.jsdelivr.net/gh/yousef-nageh/quran_library@main/assets/jsons/saadi.json.gz',
    'surahs_name.json': 'https://cdn.jsdelivr.net/gh/yousef-nageh/quran_library@main/assets/jsons/surahs_name.json.gz',
  };

  static final _initOnce = _initialize();
  static bool get _isInitialized => _root.isNotEmpty;

  static Future<void> _initialize() async {
    final docDir = await getApplicationDocumentsDirectory();
    final rootDir = Directory(p.join(docDir.path, _kFolder))..createSync(recursive: true);
    _root = rootDir.path;

    final missing = <_Task>[];
    for (final entry in _kAssets.entries) {
      final target = File(p.join(_root, entry.key));
      if (!target.existsSync()) missing.add(_Task(entry.key, entry.value, target));
    }
    if (missing.isEmpty) return; // already fully cached

    // download in parallel with a sane concurrency limit
    await _downloadInParallel(missing);
  }

  static Future<void> _downloadInParallel(List<_Task> tasks) async {
    final dio = Dio()
      ..options.headers['User-Agent'] = 'QuranApp/1.0'
      ..options.connectTimeout = const Duration(seconds: 10)
      ..options.receiveTimeout = const Duration(seconds: 30);

    final pool = <Future<void>>[];
    for (final t in tasks) {
      pool.add(_fetchAndDecode(dio, t));
      if (pool.length >= 4) await pool.removeAt(0); // throttle
    }
    await Future.wait(pool);
  }

  static Future<void> _fetchAndDecode(Dio dio, _Task t) async {
    try {
      final tmp = File('${t.target.path}.partial')..createSync(recursive: true);
      final rsp = await dio.get<List<int>>(t.url,
          options: Options(responseType: ResponseType.bytes));
      final decompressed = await Isolate.run(() => _gzipDecode(rsp.data!));
      await tmp.writeAsBytes(decompressed, flush: true);
      await tmp.rename(t.target.path);
      _log('💾 ${t.filename} (${(decompressed.length / 1048576).toStringAsFixed(2)} MB)');
    } catch (e, s) {
      _log('❌ ${t.filename}  –  $e');
      Error.throwWithStackTrace(
          Exception('Failed to download ${t.filename}'), s);
    }
  }

  static Uint8List _gzipDecode(List<int> compressed) {
    // zero-copy decode
    final input = compressed is Uint8List ? compressed : Uint8List.fromList(compressed);
    return Uint8List.fromList(gzip.decode(input));
  }

  static void _log(String msg) => log('[QuranDownloader] $msg');
}

/// Helper value object
class _Task {
  const _Task(this.filename, this.url, this.target);
  final String filename;
  final String url;
  final File target;
}
