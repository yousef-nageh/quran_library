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

  /// Reads a downloaded JSON file.
  ///
  /// Files that are not needed at startup (e.g. the QPC v4 and word-by-word
  /// data) are downloaded on first use.
  static Future<dynamic> loadJson(String filename) async {
    await ensureInitialized();
    final file = File(p.join(_root, filename));
    if (!file.existsSync()) {
      final url = _kAssets[filename];
      if (url == null) {
        throw StateError('"$filename" is not a known Quran data file.');
      }
      await (_onDemand[filename] ??= _downloadOnDemand(filename, url, file));
    }
    return jsonDecode(await file.readAsString());
  }

  /// Downloads a `.gz` file from [url] and returns the decompressed bytes.
  ///
  /// Used for files that are cached elsewhere (e.g. the QCF4 page fonts).
  static Future<Uint8List> downloadGzipBytes(String url) async {
    final rsp = await _dio.get<List<int>>(url,
        options: Options(responseType: ResponseType.bytes));
    return Isolate.run(() => _gzipDecode(rsp.data!));
  }

  /// Base URL of the assets served from this fork's GitHub repo via jsDelivr.
  static const cdnBaseUrl =
      'https://cdn.jsdelivr.net/gh/yousef-nageh/quran_library@main/assets';

  // ================  private  ================
  // bump the folder when the data files change so old caches are re-downloaded
  static const _kFolder = 'quran_data_v2';
  static const _kAssets = {
    'en.json': '$cdnBaseUrl/jsons/en.json.gz',
    'quran_hafs.json': '$cdnBaseUrl/jsons/quran_hafs.json.gz',
    'quranV4.json': '$cdnBaseUrl/jsons/quranV4.json.gz',
    'saadi.json': '$cdnBaseUrl/jsons/saadi.json.gz',
    'surahs_name.json': '$cdnBaseUrl/jsons/surahs_name.json.gz',
    'qpc-v4.json': '$cdnBaseUrl/jsons/qpc-v4.json.gz',
    'qpc_v4_ayah_info.json': '$cdnBaseUrl/jsons/qpc_v4_ayah_info.json.gz',
    'qpc-hafs-word-by-word.json':
        '$cdnBaseUrl/jsons/qpc-hafs-word-by-word.json.gz',
  };

  /// Files downloaded by [ensureInitialized]; the rest are fetched on demand.
  static const _kStartupFiles = {
    'en.json',
    'quranV4.json',
    'saadi.json',
    'surahs_name.json',
  };

  static final Map<String, Future<void>> _onDemand = {};

  static final _dio = Dio()
    ..options.headers['User-Agent'] = 'QuranApp/1.0'
    ..options.connectTimeout = const Duration(seconds: 10)
    ..options.receiveTimeout = const Duration(seconds: 60);

  static final _initOnce = _initialize();
  static bool get _isInitialized => _root.isNotEmpty;

  static Future<void> _initialize() async {
    final docDir = await getApplicationDocumentsDirectory();
    final rootDir = Directory(p.join(docDir.path, _kFolder))..createSync(recursive: true);
    _root = rootDir.path;

    final missing = <_Task>[];
    for (final entry in _kAssets.entries) {
      if (!_kStartupFiles.contains(entry.key)) continue;
      final target = File(p.join(_root, entry.key));
      if (!target.existsSync()) missing.add(_Task(entry.key, entry.value, target));
    }
    if (missing.isEmpty) return; // already fully cached

    // download in parallel with a sane concurrency limit
    await _downloadInParallel(missing);
  }

  static Future<void> _downloadInParallel(List<_Task> tasks) async {
    final pool = <Future<void>>[];
    for (final t in tasks) {
      pool.add(_fetchAndDecode(_dio, t));
      if (pool.length >= 4) await pool.removeAt(0); // throttle
    }
    await Future.wait(pool);
  }

  static Future<void> _downloadOnDemand(
      String filename, String url, File target) async {
    try {
      await _fetchAndDecode(_dio, _Task(filename, url, target));
    } catch (_) {
      // allow a retry on the next call
      _onDemand.remove(filename);
      rethrow;
    }
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
