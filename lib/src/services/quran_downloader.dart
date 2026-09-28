import 'dart:developer';

import 'package:quran_library/src/service/gzip_json_asset_service.dart';
import 'package:quran_library/src/services/quran_remote_assets.dart';

/// Downloader for the Quran JSON assets.
///
/// The files are fetched from the CDN by [QuranRemoteAssets] and cached on
/// disk by upstream's [GzipJsonAssetService]. [ensureInitialized] downloads
/// the files needed to open the Quran screen; the rest (QPC v4, word-by-word)
/// are downloaded on first use.
///
/// Usage:
///   await QuranDownloader.ensureInitialized();
///   final data = await QuranDownloader.loadJson('en.json');
abstract final class QuranDownloader {
  // ================  public API  ================

  /// Base URL of the assets served from this fork's GitHub repo via jsDelivr.
  static const cdnBaseUrl = QuranRemoteAssets.cdnBaseUrl;

  /// Idempotent initialiser – safe to call many times.
  ///
  /// If a download fails, the next call tries again.
  static Future<void> ensureInitialized() async {
    try {
      await (_initOnce ??= _initialize());
    } catch (_) {
      _initOnce = null;
      rethrow;
    }
  }

  /// Reads a data file by name (e.g. `en.json`), downloading it if needed.
  static Future<dynamic> loadJson(String filename) async {
    final assetPath = _kAssets[filename];
    if (assetPath == null) {
      throw StateError('"$filename" is not a known Quran data file.');
    }
    await QuranRemoteAssets.ensureDataVersion();
    return _jsonService.loadJsonDynamic(assetPath);
  }

  // ================  private  ================

  static const _jsonService = GzipJsonAssetService();

  /// Same asset paths upstream uses (see `quran_repository.dart`,
  /// `tafsir_ctrl.dart` and the `qpc_v4` loaders).
  static const _kAssets = {
    'en.json': 'packages/quran_library/assets/en.json.gz',
    'saadi.json': 'packages/quran_library/assets/saadi.json.gz',
    'surahs_name.json': 'packages/quran_library/assets/jsons/surahs_name.json.gz',
    'quranV4.json': 'packages/quran_library/assets/jsons/quranV4.json.gz',
    'quran_hafs.json': 'packages/quran_library/assets/jsons/quran_hafs.json.gz',
    'qpc-v4.json': 'packages/quran_library/assets/jsons/qpc-v4.json.gz',
    'qpc_v4_ayah_info.json':
        'packages/quran_library/assets/jsons/qpc_v4_ayah_info.json.gz',
    'qpc-hafs-word-by-word.json':
        'packages/quran_library/assets/jsons/qpc-hafs-word-by-word.json.gz',
  };

  /// Files downloaded by [ensureInitialized].
  static const _kStartupFiles = [
    'en.json',
    'quranV4.json',
    'saadi.json',
    'surahs_name.json',
  ];

  static Future<void>? _initOnce;

  static Future<void> _initialize() async {
    await QuranRemoteAssets.ensureDataVersion();
    // Warm the disk cache in parallel; already-cached files are read locally.
    await Future.wait(_kStartupFiles.map((name) async {
      try {
        await _jsonService.loadText(_kAssets[name]!);
      } catch (e, s) {
        _log('❌ $name  –  $e');
        Error.throwWithStackTrace(Exception('Failed to download $name'), s);
      }
    }));
  }

  static void _log(String msg) => log('[QuranDownloader] $msg');
}
