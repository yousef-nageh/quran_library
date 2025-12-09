import 'package:flutter/foundation.dart';

import '../../quran.dart';

class IsolateService {
  /// Static top-level function that runs in the isolate
  /// This processes the Quran JSON data in a background thread
  /// for version 1
  static QuranLoadResult processQuranData(QuranLoadParams params) {
    final List<QuranPageModel> staticPages = List.generate(
      params.quranPages,
          (index) => QuranPageModel(pageNumber: index + 1, ayahs: [], lines: []),
    );

    final List<AyahModel> ayahs = [];
    final List<SurahModel> surahs = [];
    final List<int> surahsStart = [];
    final List<int> quranStops = [];

    int hizb = 1;
    int surahsIndex = 1;
    List<AyahModel> thisSurahAyahs = [];

    // Process each ayah from JSON
    for (int i = 0; i < params.quranJson.length; i++) {
      final ayah = AyahModel.fromOriginalJson(params.quranJson[i]);

      if (ayah.surahNumber != surahsIndex) {
        surahs.last.endPage = ayahs.last.page;
        surahs.last.ayahs = thisSurahAyahs;
        surahsIndex = ayah.surahNumber!;
        thisSurahAyahs = [];
      }

      ayahs.add(ayah);
      thisSurahAyahs.add(ayah);
      staticPages[ayah.page - 1].ayahs.add(ayah);

      if (ayah.text.contains('۞')) {
        staticPages[ayah.page - 1].hizb = hizb++;
        quranStops.add(ayah.page);
      }

      if (ayah.text.contains('۩')) {
        staticPages[ayah.page - 1].hasSajda = true;
      }

      if (ayah.ayahNumber == 1) {
        ayah.text = ayah.text.replaceAll('۞', '');
        staticPages[ayah.page - 1].numberOfNewSurahs++;
        surahs.add(SurahModel(
          surahNumber: ayah.surahNumber!,
          englishName: ayah.englishName!,
          arabicName: ayah.arabicName!,
          ayahs: [],
          isDownloadedFonts: false,
        ));
        surahsStart.add(ayah.page - 1);
      }
    }

    surahs.last.endPage = ayahs.last.page;
    surahs.last.ayahs = thisSurahAyahs;

    // Fill lines for each page
    _fillPageLines(staticPages);

    return QuranLoadResult(
      staticPages: staticPages,
      ayahs: ayahs,
      surahs: surahs,
      surahsStart: surahsStart,
      quranStops: quranStops,
    );
  }

  /// Helper method to fill lines for each page
  static void _fillPageLines(List<QuranPageModel> staticPages) {
    for (QuranPageModel staticPage in staticPages) {
      List<AyahModel> ayas = [];

      for (AyahModel aya in staticPage.ayahs) {
        if (aya.ayahNumber == 1 && ayas.isNotEmpty) {
          ayas.clear();
        }

        if (aya.text.contains('\n')) {
          final lines = aya.text.split('\n');
          for (int i = 0; i < lines.length; i++) {
            bool centered = false;
            if ((aya.centered ?? false) && i == lines.length - 2) {
              centered = true;
            }
            final a = AyahModel.fromAya(
              ayah: aya,
              aya: lines[i],
              ayaText: lines[i],
              centered: centered,
            );
            ayas.add(a);
            if (i < lines.length - 1) {
              staticPage.lines.add(LineModel([...ayas]));
              ayas.clear();
            }
          }
        } else {
          ayas.add(aya);
        }
      }

      if (ayas.isNotEmpty) {
        staticPage.lines.add(LineModel([...ayas]));
      }
      ayas.clear();
    }
  }

  /// Main method to load Quran data using compute
  static Future<QuranLoadResult> loadQuranInBackground({
    required List<dynamic> quranJson,
    required int quranPages,
  }) async {
    final params = QuranLoadParams(
      quranJson: quranJson,
      quranPages: quranPages,
    );

    // Run the heavy processing in a separate isolate
    return await compute(processQuranData, params);
  }
  /// for version 3

  static QuranLoadResultV3 processQuranDataV3(QuranLoadParamsV3 params) {
    // Parse surahs from JSON
    final List<SurahModel> surahs = params.surahsJson
        .map((s) => SurahModel.fromDownloadedFontsJson(s))
        .toList();

    // Collect all ayahs from all surahs
    final List<AyahModel> allAyahs = [];
    for (final surah in surahs) {
      allAyahs.addAll(surah.ayahs);
    }

    // Group ayahs by pages
    final List<List<AyahModel>> pages = List.generate(
      params.totalPages,
          (pageIndex) {
        return allAyahs
            .where((ayah) => ayah.page == pageIndex + 1)
            .toList();
      },
    );

    return QuranLoadResultV3(
      surahs: surahs,
      allAyahs: allAyahs,
      pages: pages,
    );
  }

  /// Main method to load V3 Quran data using compute
  static Future<QuranLoadResultV3> loadQuranV3InBackground({
    required List<dynamic> surahsJson,
    int totalPages = 604,
  }) async {
    final params = QuranLoadParamsV3(
      surahsJson: surahsJson,
      totalPages: totalPages,
    );

    return await compute(processQuranDataV3, params);
  }
  /// for fetching surahs
  static FetchSurahsResult processSurahsJson(FetchSurahsParams params) {
    final response = SurahResponseModel.fromJson(params.jsonResponse);
    return FetchSurahsResult(surahs: response.surahs);
  }

  /// Main method to fetch and process surahs using compute
  static Future<FetchSurahsResult> fetchSurahsInBackground({
    required Map<String, dynamic> jsonResponse,
  }) async {
    final params = FetchSurahsParams(jsonResponse: jsonResponse);
    return await compute(processSurahsJson, params);
  }
}



/// for version 1
class QuranLoadParams {
  final List<dynamic> quranJson;
  final int quranPages;

  QuranLoadParams({
    required this.quranJson,
    required this.quranPages,
  });
}

/// Result returned from the isolate
class QuranLoadResult {
  final List<QuranPageModel> staticPages;
  final List<AyahModel> ayahs;
  final List<SurahModel> surahs;
  final List<int> surahsStart;
  final List<int> quranStops;

  QuranLoadResult({
    required this.staticPages,
    required this.ayahs,
    required this.surahs,
    required this.surahsStart,
    required this.quranStops,
  });
}
/// for version 3
class QuranLoadParamsV3 {
  final List<dynamic> surahsJson;
  final int totalPages;

  QuranLoadParamsV3({
    required this.surahsJson,
    this.totalPages = 604,
  });
}

/// Result for V3 processing
class QuranLoadResultV3 {
  final List<SurahModel> surahs;
  final List<AyahModel> allAyahs;
  final List<List<AyahModel>> pages;

  QuranLoadResultV3({
    required this.surahs,
    required this.allAyahs,
    required this.pages,
  });
}
/// Params for fetching surahs
class FetchSurahsParams {
  final Map<String, dynamic> jsonResponse;

  FetchSurahsParams({required this.jsonResponse});
}

/// Result for fetching surahs
class FetchSurahsResult {
  final List<SurahNamesModel> surahs;

  FetchSurahsResult({required this.surahs});
}