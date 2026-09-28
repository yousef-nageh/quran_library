import 'dart:io' as io;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:quran_library/src/services/quran_remote_assets.dart';
import 'package:quran_library/src/services/quran_static_fonts.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.docsPath);

  final String docsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;
}

/// Serves the repo's `assets/...` files as if they came from the CDN.
Future<Response<List<int>>> _serveRepoFile(String url) async {
  final path = url.substring(QuranRemoteAssets.cdnBaseUrl.length + 1);
  final bytes = await io.File('assets/$path').readAsBytes();
  return Response<List<int>>(
    requestOptions: RequestOptions(path: url),
    statusCode: 200,
    data: bytes,
    headers: Headers.fromMap({
      Headers.contentLengthHeader: ['${bytes.length}'],
    }),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late io.Directory docs;

  setUp(() async {
    docs = await io.Directory.systemTemp.createTemp('quran_static_fonts_');
    PathProviderPlatform.instance = _FakePathProvider(docs.path);
    QuranRemoteAssets.retryDelays = const [Duration.zero];
    QuranRemoteAssets.debugLoader = null;
  });

  tearDown(() async {
    QuranRemoteAssets.debugFetch = null;
    if (await docs.exists()) await docs.delete(recursive: true);
  });

  test('every font file in the list exists in the repo and is complete', () {
    for (final file in QuranStaticFonts.families.values.expand((f) => f)) {
      final bytes = io.File('assets/fonts/$file').readAsBytesSync();
      expect(QuranRemoteAssets.isCompleteFont(bytes), isTrue, reason: file);
    }
  });

  test('a cut font file is rejected', () {
    final bytes =
        io.File('assets/fonts/UthmanicHafs_V20.ttf').readAsBytesSync();
    expect(QuranRemoteAssets.isCompleteFont(bytes.sublist(0, bytes.length - 1)),
        isFalse);
    expect(QuranRemoteAssets.isCompleteFont(bytes.sublist(0, 1000)), isFalse);
  });

  test('downloads, registers and caches all fonts', () async {
    var downloads = 0;
    QuranRemoteAssets.debugFetch = (url) {
      downloads++;
      return _serveRepoFile(url);
    };

    await QuranStaticFonts.ensureLoaded();

    final fileCount = QuranStaticFonts.families.values.expand((f) => f).length;
    expect(downloads, fileCount);
    final cacheDir = io.Directory('${docs.path}/quran_static_fonts');
    expect(
        cacheDir
            .listSync()
            .whereType<io.File>()
            .where((f) => f.path.endsWith('.ttf')),
        hasLength(fileCount));
  });
}
