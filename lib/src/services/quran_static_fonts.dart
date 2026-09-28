import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:path_provider/path_provider.dart';

import 'quran_remote_assets.dart';

/// Fork: the package's static fonts (kufi, naskh, hafs, cairo, bismillah,
/// ayahNumber, surah-name-v4) are not bundled in `pubspec.yaml`; they are
/// downloaded once from the CDN, cached on disk, and registered under the
/// same family names upstream code uses, so no `fontFamily:` usage changes.
abstract final class QuranStaticFonts {
  /// Family → font files in `assets/fonts/` (weights are read from the files).
  static const families = <String, List<String>>{
    'kufi': ['Kufam-Regular.ttf'],
    'naskh': ['NotoNaskhArabic-VariableFont_wght.ttf'],
    'hafs': ['UthmanicHafs_V20.ttf'],
    'cairo': [
      'Cairo-Bold.ttf',
      'Cairo-SemiBold.ttf',
      'Cairo-Medium.ttf',
      'Cairo-Regular.ttf',
    ],
    'bismillah': ['vertopal.com_QCF_Bismillah-Regular.ttf'],
    'ayahNumber': ['Uthmanic_NeoCOLORD-Regular.ttf'],
    'surah-name-v4': ['surah-name-v4.ttf'],
  };

  static const _cacheDirName = 'quran_static_fonts';

  static Future<void>? _loading;

  /// Downloads (first time only) and registers all fonts.
  ///
  /// Safe to call many times; after a failure the next call tries again and
  /// only downloads the fonts that are still missing.
  static Future<void> ensureLoaded() async {
    try {
      await (_loading ??= _loadAll());
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  static Future<void> _loadAll() async {
    final cacheDir = await _cacheDir();
    final failed = <String>[];
    await Future.wait(families.entries.map((entry) async {
      try {
        final fonts = await Future.wait(
            entry.value.map((file) => _fontBytes(file, cacheDir)));
        // Registered with and without the package prefix: upstream uses both
        // `TextStyle(fontFamily: 'cairo', package: 'quran_library')` and
        // plain `fontFamily: 'cairo'`.
        for (final name in [entry.key, 'packages/quran_library/${entry.key}']) {
          final loader = FontLoader(name);
          for (final bytes in fonts) {
            loader.addFont(Future.value(ByteData.sublistView(bytes)));
          }
          await loader.load();
        }
      } catch (e) {
        log('[QuranStaticFonts] ❌ ${entry.key} – $e');
        failed.add(entry.key);
      }
    }));
    if (failed.isNotEmpty) {
      throw Exception('Failed to load fonts: ${failed.join(', ')}');
    }
  }

  static Future<Uint8List> _fontBytes(String file, Directory? cacheDir) async {
    final cached = cacheDir == null ? null : File('${cacheDir.path}/$file');
    if (cached != null && cached.existsSync()) {
      final bytes = await cached.readAsBytes();
      if (QuranRemoteAssets.isCompleteFont(bytes)) return bytes;
      await cached.delete(); // broken copy, download again
    }

    final data =
        await QuranRemoteAssets.load('packages/quran_library/assets/fonts/$file');
    // QuranRemoteAssets already retried until the whole font arrived.
    final bytes = Uint8List.sublistView(data);

    if (cached != null) {
      try {
        final tmp = File('${cached.path}.tmp');
        await tmp.writeAsBytes(bytes, flush: true);
        await tmp.rename(cached.path);
      } catch (e) {
        log('[QuranStaticFonts] cache write failed for $file: $e');
      }
    }
    return bytes;
  }

  static Future<Directory?> _cacheDir() async {
    if (kIsWeb) return null;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/$_cacheDirName');
      if (!dir.existsSync()) await dir.create(recursive: true);
      return dir;
    } catch (e) {
      log('[QuranStaticFonts] no cache dir: $e');
      return null;
    }
  }
}
