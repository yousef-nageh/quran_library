part of '/quran.dart';

class QpcV4AssetsStore {
  final Map<int, QpcV4Word> wordsById;
  final Map<int, List<QpcV4AyahInfoLine>> linesByPage;

  const QpcV4AssetsStore({
    required this.wordsById,
    required this.linesByPage,
  });
}

class QpcV4AssetsLoader {
  static Future<QpcV4AssetsStore> load() async {
    // Downloaded on first use via QuranDownloader (not bundled in the package)
    final ayahInfoDecoded =
        await QuranDownloader.loadJson('qpc_v4_ayah_info.json');
    if (ayahInfoDecoded is! List) {
      throw const FormatException('qpc_v4_ayah_info.json must be a JSON List');
    }

    final linesByPage = <int, List<QpcV4AyahInfoLine>>{};
    for (final item in ayahInfoDecoded) {
      if (item is! Map) continue;
      final line = QpcV4AyahInfoLine.fromJson(Map<String, dynamic>.from(item));
      (linesByPage[line.pageNumber] ??= <QpcV4AyahInfoLine>[]).add(line);
    }

    for (final entry in linesByPage.entries) {
      entry.value.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
    }

    final wordsDecoded = await QuranDownloader.loadJson('qpc-v4.json');
    if (wordsDecoded is! Map) {
      throw const FormatException('qpc-v4.json must be a JSON Map');
    }

    final wordsById = <int, QpcV4Word>{};
    for (final value in wordsDecoded.values) {
      if (value is! Map) continue;
      final word = QpcV4Word.fromJson(Map<String, dynamic>.from(value));
      wordsById[word.id] = word;
    }

    return QpcV4AssetsStore(wordsById: wordsById, linesByPage: linesByPage);
  }
}
