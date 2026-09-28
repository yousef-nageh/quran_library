import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/// Loads the package's data assets from this fork's CDN instead of the
/// app bundle, so the JSON files and QCF4 fonts don't ship inside the package.
///
/// Upstream code keeps using its normal asset paths
/// (`packages/quran_library/assets/...`); only the two upstream loaders call
/// [load] instead of `rootBundle.load` (see FORK_CHANGES.md). The repo keeps
/// the same `assets/` layout as upstream, so the CDN path equals the asset path.
abstract final class QuranRemoteAssets {
  /// Base URL of the assets served from this fork's GitHub repo via jsDelivr.
  static const cdnBaseUrl =
      'https://cdn.jsdelivr.net/gh/yousef-nageh/quran_library@main/assets';

  /// Bump this when the JSON files on the server change, so the decoded JSON
  /// cached on users' devices is cleared and downloaded again.
  static const dataVersion = 2;

  static const _assetPrefix = 'packages/quran_library/assets/';

  /// Folder where upstream's `GzipJsonAssetService` caches decoded JSON.
  static const _jsonCacheDirName = 'quran_library_json_cache';
  static const _versionFileName = 'fork_data_version.txt';

  /// Replaces the network loader (tests only).
  @visibleForTesting
  static Future<ByteData> Function(String assetPath)? debugLoader;

  static final _dio = Dio()
    ..options.headers['User-Agent'] = 'QuranApp/1.0'
    ..options.connectTimeout = const Duration(seconds: 10)
    ..options.receiveTimeout = const Duration(seconds: 60);

  static Future<void>? _versionCheck;

  /// Loads [assetPath]: from the CDN for package data assets, otherwise from
  /// the app bundle.
  static Future<ByteData> load(String assetPath) async {
    final loader = debugLoader;
    if (loader != null) return loader(assetPath);
    if (!assetPath.startsWith(_assetPrefix)) return rootBundle.load(assetPath);

    final url = urlFor(assetPath);
    try {
      final rsp = await _dio.get<List<int>>(url,
          options: Options(responseType: ResponseType.bytes));
      final bytes = Uint8List.fromList(rsp.data!);
      log('[QuranRemoteAssets] 💾 $url '
          '(${(bytes.length / 1048576).toStringAsFixed(2)} MB)');
      return ByteData.sublistView(bytes);
    } catch (e) {
      log('[QuranRemoteAssets] ❌ $url – $e');
      rethrow;
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
