import 'dart:developer';
import 'dart:io';

import 'package:archive/archive.dart' show GZipDecoder, getCrc32;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'background_task.dart';

/// Loads the package's data assets from this fork's CDN instead of the
/// app bundle, so the JSON files and QCF4 fonts don't ship inside the package.
///
/// Upstream code keeps using its normal asset paths
/// (`packages/quran_library/assets/...`); only the two upstream loaders call
/// [load] instead of `rootBundle.load` (see FORK_CHANGES.md). The repo keeps
/// the same `assets/` layout as upstream, so the CDN path equals the asset path.
abstract final class QuranRemoteAssets {
  /// Git branch or tag of this fork whose `assets/` folder is served.
  /// Set it back to `main` once this branch is merged.
  static const cdnRef = 'main';

  /// Base URL of the assets served from this fork's GitHub repo via jsDelivr.
  static const cdnBaseUrl =
      'https://cdn.jsdelivr.net/gh/yousef-nageh/quran_library@$cdnRef/assets';

  /// Bump this when the JSON files on the server change, so the decoded JSON
  /// cached on users' devices is cleared and downloaded again.
  static const dataVersion = 3;

  static const _assetPrefix = 'packages/quran_library/assets/';

  /// Folder where upstream's `GzipJsonAssetService` caches decoded JSON.
  static const _jsonCacheDirName = 'quran_library_json_cache';
  static const _versionFileName = 'fork_data_version.txt';

  /// Replaces the network loader (tests only).
  @visibleForTesting
  static Future<ByteData> Function(String assetPath)? debugLoader;

  static final _dio = Dio()
    ..options.headers['User-Agent'] = 'QuranApp/1.0'
    ..options.connectTimeout = const Duration(seconds: 15)
    ..options.receiveTimeout = const Duration(seconds: 120);

  /// Waits between attempts; its length + 1 is the number of attempts.
  @visibleForTesting
  static List<Duration> retryDelays = const [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  /// Replaces the HTTP request only (tests only), so retry and the
  /// completeness check still run.
  @visibleForTesting
  static Future<Response<List<int>>> Function(String url)? debugFetch;

  static Future<void>? _versionCheck;

  /// Loads [assetPath]: from the CDN for package data assets, otherwise from
  /// the app bundle.
  ///
  /// Network errors are retried (see [retryDelays]) and a file is only
  /// returned when it arrived complete, so a broken download is never cached.
  static Future<ByteData> load(String assetPath) async {
    final loader = debugLoader;
    if (loader != null) return loader(assetPath);
    if (!assetPath.startsWith(_assetPrefix)) return rootBundle.load(assetPath);

    final url = urlFor(assetPath);
    final attempts = retryDelays.length + 1;
    for (var attempt = 1;; attempt++) {
      try {
        final bytes = await _download(url);
        log('[QuranRemoteAssets] 💾 $url '
            '(${(bytes.length / 1048576).toStringAsFixed(2)} MB)');
        return ByteData.sublistView(bytes);
      } catch (e) {
        final retry = attempt < attempts && _isRetryable(e);
        log('[QuranRemoteAssets] ❌ attempt $attempt/$attempts $url – $e'
            '${retry ? ' (retrying)' : ''}');
        if (!retry) rethrow;
        await Future<void>.delayed(retryDelays[attempt - 1]);
      }
    }
  }

  static Future<Uint8List> _download(String url) async {
    final fetch = debugFetch;
    final rsp = fetch != null
        ? await fetch(url)
        : await _dio.get<List<int>>(url,
            options: Options(responseType: ResponseType.bytes));
    final data = rsp.data;
    if (data == null || data.isEmpty) {
      throw const IncompleteDownloadException('empty response');
    }
    final bytes = data is Uint8List ? data : Uint8List.fromList(data);

    // The server's size must match (skip when the body was re-compressed).
    final expected =
        int.tryParse(rsp.headers.value(Headers.contentLengthHeader) ?? '');
    final encoded = rsp.headers.value('content-encoding') != null;
    if (expected != null && !encoded && expected != bytes.length) {
      throw IncompleteDownloadException(
          'got ${bytes.length} of $expected bytes');
    }

    // A .gz must match its own trailer (CRC32 + size), which proves it is
    // complete. The decoders don't check this: a cut file decodes silently.
    if (url.endsWith('.gz') &&
        !await runInBackground(() => isCompleteGzip(bytes))) {
      throw const IncompleteDownloadException('gzip data is cut or corrupt');
    }
    if ((url.endsWith('.ttf') || url.endsWith('.otf')) &&
        !isCompleteFont(bytes)) {
      throw const IncompleteDownloadException('font file is cut or corrupt');
    }
    return bytes;
  }

  /// Whether [bytes] is a whole TrueType/OpenType file: every table listed in
  /// its header lies inside the data (a cut download fails this).
  static bool isCompleteFont(Uint8List bytes) {
    if (bytes.length < 12) return false;
    final data = ByteData.sublistView(bytes);
    final tag = data.getUint32(0);
    const trueType = 0x00010000, otto = 0x4F54544F, trueTag = 0x74727565;
    if (tag != trueType && tag != otto && tag != trueTag) return false;
    final numTables = data.getUint16(4);
    if (numTables == 0 || 12 + numTables * 16 > bytes.length) return false;
    for (var i = 0; i < numTables; i++) {
      final record = 12 + i * 16;
      final offset = data.getUint32(record + 8);
      final length = data.getUint32(record + 12);
      if (offset + length > bytes.length) return false;
    }
    return true;
  }

  /// Whether [bytes] is a whole gzip file: it decodes, and the CRC32 and
  /// size stored in its last 8 bytes match the decoded data.
  @visibleForTesting
  static bool isCompleteGzip(Uint8List bytes) {
    if (bytes.length < 18 || bytes[0] != 0x1f || bytes[1] != 0x8b) {
      return false;
    }
    final List<int> decoded;
    try {
      decoded = const GZipDecoder().decodeBytes(bytes);
    } catch (_) {
      return false;
    }
    final trailer = ByteData.sublistView(bytes, bytes.length - 8);
    final crc = trailer.getUint32(0, Endian.little);
    final size = trailer.getUint32(4, Endian.little);
    return size == (decoded.length & 0xFFFFFFFF) && crc == getCrc32(decoded);
  }

  static bool _isRetryable(Object e) {
    if (e is IncompleteDownloadException) return true;
    if (e is SocketException || e is HttpException) return true;
    if (e is! DioException) return false;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return true;
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        return code >= 500 || code == 408 || code == 429;
      default:
        // badCertificate, cancel, and any type added in a newer dio
        return false;
    }
  }

  /// CDN URL of a `packages/quran_library/assets/...` path.
  static String urlFor(String assetPath) =>
      '$cdnBaseUrl/${assetPath.substring(_assetPrefix.length)}';

  /// Clears the cached JSON once whenever [dataVersion] changes.
  static Future<void> ensureDataVersion() =>
      _versionCheck ??= _checkDataVersion();

  static Future<void> _checkDataVersion() async {
    if (kIsWeb) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${docs.path}/$_jsonCacheDirName');
      final versionFile = File('${docs.path}/$_versionFileName');
      final stored = versionFile.existsSync()
          ? int.tryParse(versionFile.readAsStringSync().trim())
          : null;
      if (stored == dataVersion) return;
      if (cacheDir.existsSync()) await cacheDir.delete(recursive: true);
      await versionFile.writeAsString('$dataVersion', flush: true);
    } catch (e) {
      log('[QuranRemoteAssets] data version check failed: $e');
    }
  }
}

/// A download ended before the whole file arrived.
class IncompleteDownloadException implements Exception {
  const IncompleteDownloadException(this.message);
  final String message;

  @override
  String toString() => 'IncompleteDownloadException: $message';
}
