import 'package:flutter/foundation.dart';

import '../../quran.dart';

class IsolateService {
  /// for version 3

  static QuranLoadResultV3 processQuranDataV3(QuranLoadParamsV3 params) {
    // Parse surahs from JSON
    final List<SurahModel> surahs = params.surahsJson
        .map((s) => SurahModel.fromDownloadedFontsJson(s))
        .toList();

    // Collect all ayahs from all surahs
    final List<AyahModel> allAyahs = [];
    for (final surah in surahs) {
      // نقل بيانات السورة إلى كل آية حتى يعمل البحث بشكل صحيح
      for (final ayah in surah.ayahs) {
        ayah.surahNumber ??= surah.surahNumber;
        ayah.arabicName ??= surah.arabicName;
        ayah.englishName ??= surah.englishName;
      }
      allAyahs.addAll(surah.ayahs);
    }

    // Group ayahs by pages
    final List<List<AyahModel>> pages = List.generate(
      params.totalPages,
      (pageIndex) {
        return allAyahs.where((ayah) => ayah.page == pageIndex + 1).toList();
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
