part of '/quran.dart';

/// Fork: loads the Quran data on a background isolate (see [IsolateService])
/// instead of the UI thread. Called by [QuranLibrary.prepareQuranScreen].
///
/// Once these finish, upstream's own [QuranCtrl.loadQuranDataV3] skips its
/// parsing (`surahs` is no longer empty), so the rest of upstream works as is.
///
/// NOTE (merging): [loadQuranDataV3InBackground] mirrors upstream's
/// `QuranCtrl.loadQuranDataV3()`. After each upstream merge, compare the two
/// and copy any new steps here (see FORK_CHANGES.md).
extension QuranCtrlFastLoading on QuranCtrl {
  Future<void> loadQuranDataV3InBackground() async {
    lastPage = _quranRepository.getLastPage() ?? 1;
    state.currentPageNumber.value = lastPage;

    if (surahs.isEmpty) {
      // Load JSON data from repository
      List<dynamic> surahsJson = await _quranRepository.getQuranDataV3();

      // Process data in background using IsolateService
      final result = await IsolateService.loadQuranV3InBackground(
        surahsJson: surahsJson,
        totalPages: 604,
      );

      // Update state with results from the isolate
      surahs = result.surahs;
      state.allAyahs.addAll(result.allAyahs);

      // مزامنة قائمة الآيات على مستوى الـ instance
      ayahs.addAll(state.allAyahs);
      state.pages.addAll(result.pages);
      state.isQuranLoaded = true;
      _buildAyahUqIndexIfNeeded();

      // تحميل كسول لملفات QPC v4 فقط عند تفعيل الخط المحمّل (code v4)
      if (isQpcV4Enabled) {
        // لا ننتظر هنا لتجنب إبطاء init في الحالات الأخرى.
        Future(() => _ensureQpcV4AssetsLoaded());
      }
    }

    // Always jump to the last page, not just on first load
    if (lastPage != 0) {
      jumpToPage(lastPage - 1);
    }
  }

  /// Prepares what the first visible page needs (the QPC v4 layout and the
  /// page fonts around the current page), so the loading screen is the only
  /// loader: without this, each page shows its own loader after it.
  Future<void> prepareCurrentPageInBackground() async {
    if (!isQpcV4Enabled) return;
    final page = state.currentPageNumber.value.clamp(1, 604);
    await Future.wait([
      prewarmQpcV4Pages(page - 1),
      QuranFontsService.ensurePagesLoaded(page, radius: 2),
    ]);
    // The rest of the nearby pages load while the user reads.
    unawaited(QuranFontsService.ensurePagesLoaded(page, radius: 10));
  }

  Future<void> fetchSurahsInBackground() async {
    if (surahsList.isNotEmpty) return;
    try {
      isLoading(true);

      // Load JSON data from repository
      final jsonResponse = await _quranRepository.getSurahs();

      // Process data in background using IsolateService
      final result = await IsolateService.fetchSurahsInBackground(
        jsonResponse: jsonResponse,
      );

      // Update state with results from the isolate
      surahsList.assignAll(result.surahs);
    } catch (e) {
      log('Error fetching data: $e');
    } finally {
      isLoading(false);
    }

    update();
  }
}
