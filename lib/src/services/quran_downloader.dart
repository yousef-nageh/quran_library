import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:quran_library/src/service/gzip_json_asset_service.dart';
import 'package:quran_library/src/services/quran_remote_assets.dart';
import 'package:quran_library/src/services/quran_static_fonts.dart';

/// Downloader for the Quran JSON assets and the static fonts.
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
    return jsonDecode(await _loadTextRepairing(assetPath));
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
    // Download in parallel. Each file that finishes is cached, so a retry
    // only downloads the ones that failed.
    final failed = <String>[];
    Object? firstError;
    StackTrace? firstStack;
    // The static fonts (hafs, cairo, ...) download alongside the JSON.
    final fonts = QuranStaticFonts.ensureLoaded().then<void>((_) {},
        onError: (Object e, StackTrace s) {
      _log('❌ fonts  –  $e');
      failed.add('fonts');
      firstError ??= e;
      firstStack ??= s;
    });
    await Future.wait(_kStartupFiles.map((name) async {
      try {
        await _loadTextRepairing(_kAssets[name]!);
      } catch (e, s) {
        _log('❌ $name  –  $e');
        failed.add(name);
        firstError ??= e;
        firstStack ??= s;
      }
    }));
    await fonts;
    if (failed.isNotEmpty) {
      Error.throwWithStackTrace(
          Exception('Failed to download ${failed.join(', ')}: $firstError'),
          firstStack!);
    }
  }

  /// Loads [assetPath] and checks it is complete JSON (parsed off the UI
  /// thread). If the cached copy is broken (e.g. saved by an older version
  /// from an incomplete download), deletes it and downloads it again once.
  static Future<String> _loadTextRepairing(String assetPath) async {
    try {
      return await _loadValidText(assetPath);
    } on FormatException catch (e) {
      _log('⚠ broken cache for $assetPath ($e), downloading again');
      final path = await _jsonService.diskCachePathFor(assetPath);
      if (path != null) {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      }
      GzipJsonAssetService.clearCache();
      return _loadValidText(assetPath);
    }
  }

  static Future<String> _loadValidText(String assetPath) async {
    final text = await _jsonService.loadText(assetPath);
    await Isolate.run(() {
      jsonDecode(text); // throws FormatException when incomplete
    });
    return text;
  }

  static void _log(String msg) => log('[QuranDownloader] $msg');
}
