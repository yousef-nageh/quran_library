import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:quran_library/src/service/gzip_json_asset_service.dart';
import 'package:quran_library/src/services/quran_downloader.dart';
import 'package:quran_library/src/services/quran_remote_assets.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.docsPath);

  final String docsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;
}

const _assetPath = 'packages/quran_library/assets/en.json.gz';

List<int> _gz(Object json) => io.gzip.encode(utf8.encode(jsonEncode(json)));

Response<List<int>> _ok(String url, List<int> body, {int? contentLength}) =>
    Response<List<int>>(
      requestOptions: RequestOptions(path: url),
      statusCode: 200,
      data: body,
      headers: Headers.fromMap({
        Headers.contentLengthHeader: ['${contentLength ?? body.length}'],
      }),
    );

DioException _dioError(String url, DioExceptionType type, {int? status}) =>
    DioException(
      requestOptions: RequestOptions(path: url),
      type: type,
      response: status == null
          ? null
          : Response(
              requestOptions: RequestOptions(path: url), statusCode: status),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late io.Directory docs;

  setUp(() async {
    docs = await io.Directory.systemTemp.createTemp('quran_remote_assets_');
    PathProviderPlatform.instance = _FakePathProvider(docs.path);
    QuranRemoteAssets.retryDelays = const [
      Duration.zero,
      Duration.zero,
      Duration.zero,
    ];
    QuranRemoteAssets.debugLoader = null;
    GzipJsonAssetService.clearCache();
  });

  tearDown(() async {
    QuranRemoteAssets.debugFetch = null;
    if (await docs.exists()) await docs.delete(recursive: true);
  });

  test('retries network errors and returns the file', () async {
    final body = _gz({'1:1': 'In the name of Allah'});
    var calls = 0;
    QuranRemoteAssets.debugFetch = (url) async {
      calls++;
      if (calls < 3) throw _dioError(url, DioExceptionType.connectionError);
      return _ok(url, body);
    };

    final data = await QuranRemoteAssets.load(_assetPath);

    expect(calls, 3);
    expect(data.lengthInBytes, body.length);
  });

  test('rejects a truncated .gz and never returns it', () async {
    final full = _gz(List.generate(500, (i) => {'aya': i, 'text': 'x' * 40}));
    final truncated = full.sublist(0, full.length ~/ 2);
    var calls = 0;
    QuranRemoteAssets.debugFetch = (url) async {
      calls++;
      return _ok(url, truncated);
    };

    await expectLater(QuranRemoteAssets.load(_assetPath),
        throwsA(isA<IncompleteDownloadException>()));
    expect(calls, 4, reason: '1 try + 3 retries');
  });

  test('a file cut by only a few bytes is detected', () {
    final full = Uint8List.fromList(_gz({'k': 'v' * 1000}));
    expect(QuranRemoteAssets.isCompleteGzip(full), isTrue);
    for (final missing in [1, 4, 8, 20]) {
      expect(
          QuranRemoteAssets.isCompleteGzip(
              full.sublist(0, full.length - missing)),
          isFalse,
          reason: 'missing $missing bytes');
    }
  });

  test('every real data file in assets/ is accepted', () {
    final files = [
      ...io.Directory('assets').listSync().whereType<io.File>(),
      ...io.Directory('assets/jsons').listSync().whereType<io.File>(),
      ...io.Directory('assets/fonts/quran_fonts_qfc4')
          .listSync()
          .whereType<io.File>()
          .take(20),
    ].where((f) => f.path.endsWith('.gz'));
    expect(files, isNotEmpty);
    for (final f in files) {
      expect(QuranRemoteAssets.isCompleteGzip(f.readAsBytesSync()), isTrue,
          reason: f.path);
    }
  });

  test('retries when fewer bytes arrive than Content-Length', () async {
    final body = _gz({'a': 1});
    var calls = 0;
    QuranRemoteAssets.debugFetch = (url) async {
      calls++;
      return calls == 1
          ? _ok(url, body, contentLength: body.length + 100)
          : _ok(url, body);
    };

    await QuranRemoteAssets.load(_assetPath);
    expect(calls, 2);
  });

  test('does not retry a 404', () async {
    var calls = 0;
    QuranRemoteAssets.debugFetch = (url) async {
      calls++;
      throw _dioError(url, DioExceptionType.badResponse, status: 404);
    };

    await expectLater(
        QuranRemoteAssets.load(_assetPath), throwsA(isA<DioException>()));
    expect(calls, 1);
  });

  test('QuranDownloader repairs a broken cached file', () async {
    final json = {'1:1': 'complete'};
    QuranRemoteAssets.debugFetch = (url) async => _ok(url, _gz(json));
    await QuranRemoteAssets.ensureDataVersion();

    // A cache file saved from an incomplete download by an older version.
    final cachePath =
        (await const GzipJsonAssetService().diskCachePathFor(_assetPath))!;
    io.File(cachePath)
      ..createSync(recursive: true)
      ..writeAsStringSync('{"1:1": "compl');

    final data = await QuranDownloader.loadJson('en.json');

    expect(data, json);
    expect(jsonDecode(io.File(cachePath).readAsStringSync()), json,
        reason: 'the cache now holds the complete file');
  });
}
