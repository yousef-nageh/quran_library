part of '/quran.dart';

/// A class that provides utility functions for interacting with the Quran library.
///
/// This class includes methods and properties that facilitate various operations
/// related to the Quran, such as retrieving verses, chapters, and other relevant
/// information.
///
/// Example usage:
///
/// ```dart
/// QuranLibrary quranLibrary = QuranLibrary();
/// // Use quranLibrary to access various Quran-related utilities.
/// ```
///
/// Note: Ensure that you have the necessary dependencies and configurations
/// set up in your Flutter project to use this class effectively.
class QuranLibrary {
  // Cache for frequently accessed data
  static final Map<String, dynamic> _cache = {};
  static bool _isInitialized = false;

  /// [init] تقوم بتهيئة القرآن ويجب استدعاؤها قبل البدء في استخدام الحزمة
  ///
  /// [init] initializes the FlutterQuran,
  /// and must be called before starting using the package
  static Future<void> init(
      {Map<int, List<BookmarkModel>>? userBookmarks,
      bool overwriteBookmarks = false}) async {
    if (_isInitialized) return;

    await GetStorage.init();

    // Initialize state values
    final storage = GetStorage();
    final storageConstants = _StorageConstants();

    /// Initialize SurahAudioController
    QuranCtrl.instance;
    await _initTafsir();

    quranCtrl.state.isFontDownloaded.value =
        storage.read(storageConstants.isDownloadedCodeV4Fonts) ?? false;
    quranCtrl.state.isBold.value =
        storage.read(storageConstants.isBold) ?? false;
    quranCtrl.state.fontsSelected.value =
        storage.read(storageConstants.fontsSelected) ?? 0;
    quranCtrl.state.fontsDownloadedList.value = (storage
            .read<List<dynamic>>(storageConstants.fontsDownloadedList)
            ?.cast<int>() ??
        []);

    if (!kIsWeb) {
      QuranCtrl.instance.deleteOldFonts();
    }

    // Load data in parallel
    final futures = <Future<void>>[
      QuranCtrl.instance.loadQuranDataV1(),
      QuranCtrl.instance.loadQuranDataV3(),
      QuranCtrl.instance.fetchSurahs(),
    ];

    await Future.wait<void>(futures);

    // تسجيل الخطوط المحفوظة دفعة واحدة في الخلفية إن كانت متاحة
    // if (kIsWeb) {
    //   // على الويب: لا تنزيلات مسبقة. سجّل فقط الصفحات التي تم تحميلها سابقًا (إن وُجدت)
    //   final stored = storage
    //           .read<List<dynamic>>(storageConstants.loadedFontPages)
    //           ?.cast<int>() ??
    //       const <int>[];
    //   if (stored.isNotEmpty) {
    //     Future(() => QuranCtrl.instance
    //         .loadPersistedFontsBulk(pages: stored, batchSize: 16));
    //   }
    // } else if (quranCtrl.state.isFontDownloaded.value) {
    //   // على المنصات الأخرى: سجّل الصفحات المحفوظة فقط (دع الدالة تقرأ من التخزين)
    //   QuranCtrl.instance.loadPersistedFontsBulk();
    // }

    // Initialize bookmarks
    BookmarksCtrl.instance.initBookmarks(
        userBookmarks: userBookmarks, overwrite: overwriteBookmarks);

    _isInitialized = true;
  }

  /// A singleton instance of the `QuranCtrl` class.
  ///
  /// This instance is used to access the functionalities provided by the
  /// `QuranCtrl` class throughout the application.
  static final quranCtrl = QuranCtrl.instance;

  /// [currentPageNumber] تعيد رقم الصفحة التي يكون المستخدم عليها حاليًا.
  /// أرقام الصفحات تبدأ من 1، لذا فإن الصفحة الأولى من القرآن هي الصفحة رقم 1.
  ///
  /// [currentPageNumber] Returns the page number of the page that the user is currently on.
  /// Page numbers start at 1, so the first page of the Quran is page 1.
  int get currentPageNumber => quranCtrl.lastPage;

  /// [search] يبحث في القرآن عن الآيات من خلال الكلمة أو رقم الصفحة.
  /// يعيد قائمة بجميع الآيات التي تحتوي نصوصها على النص المُعطى.
  ///
  /// [search] searches the Qur'an for verses by word or page number.
  /// Returns a list of all verses whose texts contain the given text.
  List<AyahModel> search(String text) {
    final cacheKey = 'search_$text';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as List<AyahModel>;
    }
    final results = quranCtrl.search(text);
    _cache[cacheKey] = results;
    return results;
  }

  /// [search] يبحث في القرآن عن أسماء السور.
  /// يعيد قائمة بجميع السور التي يكون أسمها أو رقمها أو رفم الصفحة الخاصة بها مطابق للنص المُعطى.
  ///
  /// [search] Searches the Qur'an for the names of the surahs.
  /// Returns a list of all surahs whose name, number, or page number matches the given text.
  List<SurahModel> surahSearch(String text) {
    final cacheKey = 'surah_search_$text';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as List<SurahModel>;
    }
    final results = quranCtrl.searchSurah(text);
    _cache[cacheKey] = results;
    return results;
  }

  /// [navigateToAyah] يتيح لك التنقل إلى أي آية.
  /// من الأفضل استدعاء هذه الطريقة أثناء عرض شاشة القرآن،
  /// وإذا تم استدعاؤها ولم تكن شاشة القرآن معروضة،
  /// فسيتم بدء العرض من صفحة هذه الآية عند فتح شاشة القرآن في المرة التالية.
  ///
  /// [jumpToAyah] let's you navigate to any ayah..
  /// It's better to call this method while Quran screen is displayed
  /// and if it's called and the Quran screen is not displayed, the next time you
  /// open quran screen it will start from this ayah's page
  void jumpToAyah(int pageNumber, int ayahUQNumber) {
    quranCtrl.jumpToPage(pageNumber - 1);
    quranCtrl.toggleAyahSelection(ayahUQNumber);
    Future.delayed(const Duration(seconds: 3))
        .then((_) => quranCtrl.toggleAyahSelection(ayahUQNumber));
  }

  /// [jumpToPage] يتيح لك التنقل إلى أي صفحة في القرآن باستخدام رقم الصفحة.
  /// ملاحظة: تستقبل هذه الطريقة رقم الصفحة وليس فهرس الصفحة.
  /// من الأفضل استدعاء هذه الطريقة أثناء عرض شاشة القرآن،
  /// وإذا تم استدعاؤها ولم تكن شاشة القرآن معروضة،
  /// فسيتم بدء العرض من هذه الصفحة عند فتح شاشة القرآن في المرة التالية.
  ///
  /// [jumpToPage] let's you navigate to any quran page with page number
  /// Note it receives page number not page index
  /// It's better to call this method while Quran screen is displayed
  /// and if it's called and the Quran screen is not displayed, the next time you
  /// open quran screen it will start from this page
  void jumpToPage(int page) => quranCtrl.jumpToPage(page - 1);

  /// [jumpToJoz] let's you navigate to any quran jozz with jozz number
  /// Note it receives jozz number not jozz index
  void jumpToJoz(int jozz) =>
      jumpToPage(jozz == 1 ? 0 : (quranCtrl.quranStops[(jozz - 1) * 8 - 1]));

  /// [jumpToHizb] يتيح لك التنقل إلى أي جزء في القرآن باستخدام رقم الجزء.
  /// ملاحظة: تستقبل هذه الطريقة رقم الجزء وليس فهرس الجزء.
  ///
  /// [jumpToHizb] let's you navigate to any quran hizb with hizb number
  /// Note it receives hizb number not hizb index
  void jumpToHizb(int hizb) =>
      jumpToPage(hizb == 1 ? 0 : (quranCtrl.quranStops[(hizb - 1) * 4 - 1]));

  /// [jumpToBookmark] يتيح لك التنقل إلى علامة مرجعية معينة.
  /// ملاحظة: يجب أن يكون رقم صفحة العلامة المرجعية بين 1 و604.
  ///
  /// [jumpToBookmark] let's you navigate to a certain bookmark
  /// Note that bookmark page number must be between 1 and 604
  void jumpToBookmark(BookmarkModel bookmark) {
    if (bookmark.page > 0 && bookmark.page <= 604) {
      jumpToPage(bookmark.page);
    } else {
      throw Exception("Page number must be between 1 and 604");
    }
  }

  /// [jumpToSurah] يتيح لك التنقل إلى أي سورة في القرآن باستخدام رقم السورة.
  /// ملاحظة: تستقبل هذه الطريقة رقم السورة وليس فهرس السورة.
  ///
  /// [jumpToSurah] let's you navigate to any quran surah with surah number
  /// Note it receives surah number not surah index
  void jumpToSurah(int surah) {
    jumpToPage(quranCtrl.surahsStart[surah - 1] + 1);
    log('Jumped to Surah $surah at page ${quranCtrl.surahsStart[surah - 1] + 1}');
  }

  /// [allJoz] returns list of all Quran joz' names
  static List<String> get allJoz {
    if (_cache.containsKey('allJoz')) {
      return _cache['allJoz'] as List<String>;
    }
    final jozList = _QuranConstants.quranHizbs
        .sublist(0, 30)
        .map((jozz) => "الجزء $jozz")
        .toList();
    _cache['allJoz'] = jozList;
    return jozList;
  }

  /// [allHizb] يعيد قائمة بأسماء جميع أجزاء القرآن.
  ///
  /// [allHizb] returns list of all Quran hizbs' names
  static List<String> get allHizb {
    if (_cache.containsKey('allHizb')) {
      return _cache['allHizb'] as List<String>;
    }
    final hizbList =
        _QuranConstants.quranHizbs.map((jozz) => "الحزب $jozz").toList();
    _cache['allHizb'] = hizbList;
    return hizbList;
  }

  /// [getAllSurahs] يعيد قائمة بأسماء السور.
  ///
  /// [getAllSurahs] returns list of all Quran surahs' names
  static List<String> getAllSurahs({bool isArabic = true}) {
    final cacheKey = 'allSurahs_${isArabic ? 'ar' : 'en'}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as List<String>;
    }
    final surahList = quranCtrl.surahs
        .map((surah) => isArabic
            ? 'سورة ${surah.arabicName}'
            : 'Surah ${surah.englishName}')
        .toList();
    _cache[cacheKey] = surahList;
    return surahList;
  }

  /// [getAllSurahsArtPath] يعيد قائمة ويدجيت المخطوطات الخاصة بإسماء السور.
  ///
  /// [getAllSurahsArtPath] returns list of widgets for all Quran surahs' name artistic manuscript path
  List<Widget> getAllSurahsArtPath(
      {Color? color, double? fontSize, bool? withSurahWord = false}) {
    if (_cache.containsKey('allSurahsArtPath')) {
      return _cache['allSurahsArtPath'] as List<Widget>;
    }
    final paths = List.generate(
        quranCtrl.surahs.length,
        (i) => Text(
              withSurahWord!
                  ? 'surah${(i + 1).toString().padLeft(3, '0')}surah-icon'
                  : 'surah${(i + 1).toString().padLeft(3, '0')}',
              style: TextStyle(
                color: color ?? Colors.black,
                fontFamily: "surah-name-v4",
                fontSize: fontSize ?? 38,
                package: "quran_library",
              ),
            ));
    _cache['allSurahsArtPath'] = paths;
    return paths;
  }

  /// [getSurahArtPath] يعيد ويدجيت المخطوطة الخاصة بإسم السور.
  ///
  /// [getSurahArtPath] returns widget for Quran surah name artistic manuscript path
  Widget getSurahArtPath(
      {required int index,
      Color? color,
      double? fontSize,
      bool? withSurahWord = false}) {
    if (_cache.containsKey('allSurahsArtPath')) {
      return _cache['allSurahsArtPath'] as Widget;
    }
    final paths = Text(
      withSurahWord!
          ? 'surah${(index + 1).toString().padLeft(3, '0')}surah-icon'
          : 'surah${(index + 1).toString().padLeft(3, '0')}',
      style: TextStyle(
        color: color ?? Colors.black,
        fontFamily: "surah-name-v4",
        fontSize: fontSize ?? 38,
        package: "quran_library",
      ),
    );
    _cache['allSurahsArtPath'] = paths;
    return paths;
  }

  /// يعيد قائمة بجميع شارات المرجعية المحفوظة [allBookmarks].
  ///
  /// [allBookmarks] returns list of all bookmarks
  List<BookmarkModel> get allBookmarks {
    if (_cache.containsKey('allBookmarks')) {
      return _cache['allBookmarks'] as List<BookmarkModel>;
    }
    final bookmarks =
        BookmarksCtrl.instance.bookmarks.values.expand((list) => list).toList();
    final result = bookmarks.sublist(0, bookmarks.length - 1);
    _cache['allBookmarks'] = result;
    return result;
  }

  /// يعيد قائمة بجميع العلامات المرجعية التي استخدمها وقام بتعيينها المستخدم في صفحات القرآن [usedBookmarks].
  ///
  /// [usedBookmarks] returns list of all bookmarks used and set by the user in quran pages
  List<BookmarkModel> get usedBookmarks {
    if (_cache.containsKey('usedBookmarks')) {
      return _cache['usedBookmarks'] as List<BookmarkModel>;
    }
    final bookmarks = BookmarksCtrl.instance.bookmarks.values
        .expand((list) => list)
        .where((bookmark) => bookmark.page != -1)
        .toList();
    _cache['usedBookmarks'] = bookmarks;
    return bookmarks;
  }

  /// للحصول على معلومات السورة في نافذة حوار، قم فقط باستدعاء: [getSurahInfoBottomSheet].
  ///
  /// مطلوب تمرير رقم السورة [surahNumber].
  /// كما أن التمرير الاختياري لنمط [SurahInfoStyle] ممكن.
  ///
  /// to get the Surah information bottomSheet just call [getSurahInfoBottomSheet]
  ///
  /// and required to pass the Surah number [surahNumber]
  /// and style [SurahInfoStyle] is optional.
  void getSurahInfoBottomSheet(
          {required int surahNumber,
          required BuildContext context,
          SurahInfoStyle? surahInfoStyle,
          String? languageCode,
          bool isDark = false}) =>
      surahInfoBottomSheetWidget(
        context,
        surahNumber - 1,
        surahStyle: surahInfoStyle,
        languageCode: languageCode,
        isDark: isDark,
      );

  /// [getSurahInfo] تتيح لك الحصول على سورة مع جميع بياناتها.
  /// ملاحظة: تستقبل هذه الطريقة رقم السورة وليس فهرس السورة.
  ///
  /// [getSurahInfo] let's you get a Surah with all its data
  /// Note it receives surah number not surah index
  SurahNamesModel getSurahInfo({required int surahNumber}) =>
      quranCtrl.surahsList[surahNumber];

  /// للحصول على نافذة حوار خاصة بتحميل الخطوط، قم فقط باستدعاء: [getFontsDownloadDialog].
  ///
  /// قم بتمرير رمز اللغة ليتم عرض الأرقام على حسب اللغة،
  /// رمز اللغة الإفتراضي هو: 'ar' [languageCode].
  /// كما أن التمرير الاختياري لنمط [DownloadFontsDialogStyle] ممكن.
  ///
  /// to get the fonts download dialog just call [getFontsDownloadDialog]
  ///
  /// and pass the language code to translate the number if you want,
  /// the default language code is 'ar' [languageCode]
  /// and style [DownloadFontsDialogStyle] is optional.
  Widget getFontsDownloadDialog(
          DownloadFontsDialogStyle? downloadFontsDialogStyle,
          String? languageCode,
          {bool isDark = false}) =>
      FontsDownloadDialog(
        downloadFontsDialogStyle: downloadFontsDialogStyle,
        languageCode: languageCode,
        isDark: isDark,
      );

  /// للحصول على الويدجت الخاصة بتنزيل الخطوط فقط قم بإستدعاء [getFontsDownloadWidget]
  ///
  /// to get the fonts download widget just call [getFontsDownloadWidget]
  Widget getFontsDownloadWidget(BuildContext context,
          {DownloadFontsDialogStyle? downloadFontsDialogStyle,
          String? languageCode,
          bool isDark = false,
          bool isFontsLocal = false}) =>
      quranCtrl.fontsDownloadWidget(
        context,
        downloadFontsDialogStyle: downloadFontsDialogStyle,
        languageCode: languageCode,
        isDark: isDark,
        isFontsLocal: isFontsLocal,
      );

  /// للحصول على طريقة تنزيل الخطوط فقط قم بإستدعاء [getFontsDownloadMethod]
  ///
  /// to get the fonts download method just call [getFontsDownloadMethod]
  Future<void> getFontsDownloadMethod({required int fontIndex}) async {
    await quranCtrl.downloadAllFontsZipFile(fontIndex);
  }

  /// للحصول على طريقة إعداد الخطوط فقط قم بإستدعاء [getFontsPrepareMethod]
  /// يمكنك تمرير ارقام الصفحات [pages]
  ///
  /// to prepare the fonts was downloaded before just call [getFontsPrepareMethod]
  /// you can pass pages numbers [pages]
  // Future<void> getFontsPrepareMethod(
  //     {List<int>? pages, int batchSize = 24}) async {
  //   await quranCtrl.loadPersistedFontsBulk(pages: pages, batchSize: batchSize);
  // }

  /// لحذف الخطوط فقط قم بإستدعاء [getDeleteFontsMethod]
  ///
  /// to delete the fonts just call [getDeleteFontsMethod]
  Future<void> getDeleteFontsMethod() async {
    await quranCtrl.deleteFonts();
  }

  /// للحصول على تقدم تنزيل الخطوط، ما عليك سوى إستدعاء [fontsDownloadProgress]
  ///
  /// to get fonts download progress just call [fontsDownloadProgress]
  double get fontsDownloadProgress {
    // قيمة تقدم التحميل كنسبة مئوية من 0 إلى 100
    // Download progress value as a percentage from 0 to 100
    double progress = quranCtrl.state.fontsDownloadProgress.value;
    // التحويل إلى قيمة بين 0 و 1 للاستخدام في LinearProgressIndicator
    // Convert to a value between 0 and 1 for use in LinearProgressIndicator
    return progress / 100;
  }

  /// لمعرفة ما إذا كانت الخطوط محملة او لا، ما عليك سوى إستدعاء [isFontsDownloaded]
  ///
  /// To find out whether fonts are downloaded or not, just call [isFontsDownloaded]
  bool get isFontsDownloaded {
    // التحقق من قيمة isDownloadedV2Fonts في GetStorage
    // Check the value of isDownloadedV2Fonts in GetStorage
    final storageValue =
        GetStorage().read<bool>(_StorageConstants().isDownloadedCodeV4Fonts);
    // تحديث قيمة المتغير في state ليتوافق مع قيمة التخزين
    // Update the state variable to match storage value
    quranCtrl.state.isFontDownloaded.value = storageValue ?? false;
    // إرجاع القيمة المحدثة
    // Return the updated value
    return quranCtrl.state.isFontDownloaded.value;
  }

  /// لمعرفة الخط الذي تم تحديده، ما عليك سوى إستدعاء [currentFontsSelected]
  ///
  /// To find out which font has been selected, just call [currentFontsSelected]
  int get currentFontsSelected => quranCtrl.state.fontsSelected.value;

  /// لمعرفة ما إذا كانت الخطوط قيد التحميل، ما عليك سوى إستدعاء [isPreparingDownloadFonts]
  ///
  /// To find out whether fonts are being downloaded, just call [isPreparingDownloadFonts]
  bool get isPreparingDownloadFonts =>
      quranCtrl.state.isPreparingDownload.value ||
      quranCtrl.state.isDownloadingFonts.value;

  /// لتبديل نوع الخط مع تحميله إذا لم يكن محملاً من قبل
  /// هذه الدالة تلقائيًا ستقوم بتحميل الخط إذا كان غير متوفر ثم تعيينه
  ///
  /// To switch font type with downloading if not already downloaded
  /// This function will automatically download the font if not available then set it
  Future<void> switchFontType({required int fontIndex}) async {
    await quranCtrl.switchFontType(fontIndex: fontIndex);
  }

  /// لتحديد نوع الخط الذي تريد إستخدامه، ما عليك سوى إعطاء قيمة [setFontsSelected]
  ///
  /// To set the font type you want to use, just give a value to [setFontsSelected]
  ///
  set setFontsSelected(int index) {
    quranCtrl.state.fontsSelected.value = index;
    GetStorage().write(_StorageConstants().fontsSelected, index);
    Get.forceAppUpdate(); // تحديث إجباري للواجهة بعد تغيير نوع الخط
  }

  /// يقوم بتعيين علامة مرجعية باستخدام [ayahId] و[page] و[bookmarkId] المحددة.
  ///
  /// [ayahId] هو معرّف الآية التي سيتم حفظها.
  /// [page] هو رقم الصفحة التي تحتوي على الآية.
  /// [bookmarkId] هو معرّف العلامة المرجعية التي سيتم حفظها.
  ///
  /// لا يمكن حفظ علامة مرجعية برقم صفحة خارج النطاق من 1 إلى 604.
  /// Sets a bookmark with the given [ayahId], [page] and [bookmarkId].
  ///
  /// [ayahId] is the id of the ayah to be saved.
  /// [page] is the page number of the ayah.
  /// [bookmarkId] is the id of the bookmark to be saved.
  ///
  /// You can't save a bookmark with a page number that is not between 1 and 604.
  void setBookmark(
          {required String surahName,
          required int ayahNumber,
          required int ayahId,
          required int page,
          required int bookmarkId}) =>
      BookmarksCtrl.instance.saveBookmark(
          surahName: surahName,
          ayahNumber: ayahNumber,
          ayahId: ayahId,
          page: page,
          colorCode: bookmarkId);

  /// يزيل علامة مرجعية من قائمة العلامات المرجعية المحفوظة للمستخدم.
  /// [bookmarkId] هو معرّف العلامة المرجعية التي سيتم إزالتها.
  ///
  /// Removes a bookmark from the list of user's saved bookmarks.
  /// [bookmarkId] is the id of the bookmark to be removed.
  void removeBookmark({required int bookmarkId}) =>
      BookmarksCtrl.instance.removeBookmark(bookmarkId);

  /// لمعرفة أسماء السور في اي صفحة فقط قم بإستدعاء [getAllSurahInPageByPageNumber]
  /// وفقط قم بتمرير رقم الصفحة لها.
  ///
  /// To know the names of the surahs on any page, just call [getAllSurahInPageByPageNumber]
  /// And just pass the page number to it.
  List<SurahModel> getAllSurahInPageByPageNumber({required int pageNumber}) =>
      quranCtrl.getSurahsByPageNumber(pageNumber);

  /// لجلب بيانات السورة الحالية عن طريق رقم الصفحة
  /// يمكنك إستخدام [getCurrentSurahDataByPageNumber].
  ///
  /// To fetch the current Surah data by page number,
  /// you can use [getCurrentSurahDataByPageNumber].
  SurahModel getCurrentSurahDataByPageNumber({required int pageNumber}) =>
      quranCtrl.getCurrentSurahByPageNumber(pageNumber);

  /// لجلب بيانات السورة الحالية عن طريق بيانات الآية
  /// يمكنك إستخدام [getCurrentSurahDataByAyah].
  ///
  /// To fetch the current Surah data by Ayah data,
  /// you can use [getCurrentSurahDataByAyah].
  SurahModel getCurrentSurahDataByAyah({required AyahModel ayah}) =>
      quranCtrl.getSurahDataByAyah(ayah);

  /// لجلب بيانات السورة الحالية عن طريق رقم الآية الفريد
  /// يمكنك إستخدام [getCurrentSurahDataByAyahUniqueNumber].
  ///
  /// To fetch the current Surah data by Ayah unique number,
  /// you can use [getCurrentSurahDataByAyahUniqueNumber].
  SurahModel getCurrentSurahDataByAyahUniqueNumber(
          {required int ayahUniqueNumber}) =>
      quranCtrl.getSurahDataByAyahUQ(ayahUniqueNumber);

  /// لجلب رقم الجزء الحالي عن طريق رقم الصفحة
  /// يمكنك إستخدام [getJuzByPageNumber].
  ///
  /// To fetch the current Juz number by page number,
  /// you can use [getJuzByPageNumber].
  AyahModel getJuzByPageNumber({required int pageNumber}) =>
      quranCtrl.getJuzByPage(pageNumber);

  /// لجلب آيات الصفحة عن طريق رقم الصفحة
  /// يمكنك إستخدام [getPageAyahsByPageNumber].
  ///
  /// To fetch the Ayahs in the page by page number,
  /// you can use [getPageAyahsByPageNumber].
  List<AyahModel> getPageAyahsByPageNumber({required int pageNumber}) =>
      quranCtrl.getPageAyahsByIndex(pageNumber - 1);

  /// لجلب آيات الصفحة عن طريق رقم الصفحة
  /// يمكنك إستخدام [getTajweedRules].
  ///
  /// To fetch the Ayahs in the page by page number,
  /// you can use [getTajweedRules].
  // List<TajweedRuleModel> getTajweedRules({required String languageCode}) =>
  //     quranCtrl.getTajweedRules(languageCode: languageCode);

  //////////// [Tafsir] ////////////

  /// تهيئة بيانات التفسير عند بدء التطبيق.
  /// Initialize tafsir data when the app starts.
  static Future<void> _initTafsir() async {
    return TafsirCtrl.instance.onInit();
  }

  /// إظهار قائمة منبثقة لتغيير نوع التفسير.
  /// Show a popup menu to change the tafsir style.
  Widget changeTafsirPopupMenu(TafsirStyle tafsirStyle,
          {int? pageNumber, bool? isDark}) =>
      ChangeTafsirDialog(
          tafsirStyle: tafsirStyle, pageNumber: pageNumber, isDark: isDark!);

  /// التحقق إذا كان التفسير تم تحميله مسبقاً.
  /// Check if the tafsir is already downloaded.
  bool getTafsirDownloaded(int index) =>
      TafsirCtrl.instance.tafsirDownloadIndexList.contains(index);

  /// الحصول على قائمة أسماء التفاسير والترجمات.
  /// Get the list of tafsir and translation names.
  List<TafsirNameModel> get tafsirAndTraslationsCollection =>
      TafsirCtrl.instance.tafsirAndTranslationsItems;

  /// تغيير التفسير المختار عند الضغط على زر التبديل.
  /// Change the selected tafsir when the switch button is pressed.
  void changeTafsirSwitch(int index, {int? pageNumber}) => TafsirCtrl.instance
      .handleRadioValueChanged(index, pageNumber: pageNumber);

  /// الحصول على قائمة بيانات التفاسير المتوفرة.
  /// Get the list of available tafsir data.
  List<TafsirTableData> get tafsirList => TafsirCtrl.instance.tafseerList;

  /// الحصول على قائمة الترجمات المتوفرة.
  /// Get the list of available translations.
  List<TranslationModel> get translationList =>
      TafsirCtrl.instance.translationList;

  /// التحقق إذا كان الوضع الحالي هو التفسير أو الترجمة.
  /// Check if the current mode is tafsir or translation.
  bool get isTafsir => TafsirCtrl.instance.selectedTafsir.isTafsir;
  bool get isTtranslation => TafsirCtrl.instance.selectedTafsir.isTranslation;

  /// التحقق إذا كان التفسير قيد التحميل حالياً.
  /// Check if the tafsir is currently being downloaded.
  bool get isPreparingDownloadTafsir =>
      TafsirCtrl.instance.isPreparingDownload.value;

  /// الحصول على رقم التفسير المختار حالياً.
  /// Get the currently selected tafsir index.
  int get selectedTafsirIndex => TafsirCtrl.instance.radioValue.value;

  /// جلب الترجمات من المصدر.
  /// Fetch translations from the source.
  Future<void> fetchTranslation() async =>
      await TafsirCtrl.instance.fetchTranslate();

  /// تحميل التفسير المحدد حسب الفهرس.
  /// Download the tafsir by the given index.
  Future<void> tafsirDownload(int i) async =>
      await TafsirCtrl.instance.tafsirAndTranslationDownload(i);

  // Future<void> initializeDatabase() async =>
  //     await TafsirCtrl.instance.initializeDatabase();

  /// جلب التفسير الخاص بصفحة معينة من خلال رقم الصفحة.
  /// Fetch tafsir for a specific page by its page number.
  Future<void> fetchTafsir({required int pageNumber}) async =>
      await TafsirCtrl.instance.fetchData(pageNumber);

  /// لعرض التفسير، يمكنك استخدام [showTafsir].
  ///
  /// To show the tafsir, you can use [showTafsir].
  Future<void> showTafsir({
    required BuildContext context,
    required int ayahNum,
    required int pageIndex,
    required String ayahTextN,
    required int ayahUQNum,
    required int ayahNumber,
    bool? isDark,
    TafsirStyle? tafsirStyle,
  }) async =>
      await TafsirCtrl.instance.showTafsirOnTap(
        context: context,
        ayahNum: ayahNum,
        pageIndex: pageIndex,
        ayahUQNum: ayahUQNum,
        ayahNumber: ayahNumber,
        isDark: isDark!,
        externalTafsirStyle: tafsirStyle ??
            TafsirStyle.defaults(isDark: isDark, context: context),
      );

  /// للحصول على التفسير الخاص بالآية،
  ///  فقط قم بتمرير رقم الآية لـ [getTafsirOfAyah].
  ///
  /// To obtain the interpretation of the verse,
  /// simply pass the verse number to [getTafsirOfAyah].
  ///
  Future<List<TafsirTableData>> getTafsirOfAyah(
      {required int ayahUniqNumber, String? databaseName}) async {
    // TafsirCtrl.instance.initializeDatabase();
    // await TafsirCtrl.instance.fetchData(pageIndex + 1);
    return await TafsirCtrl.instance
        .fetchTafsirAyah(ayahUniqNumber, databaseName: databaseName!);
  }

  /// للحصول على التفسير الخاص بايآت الصفحة،
  ///  فقط قم بتمرير رقم الصفحة لـ [getTafsirOfPage].
  ///
  /// To obtain the interpretation of the verses on the page,
  /// simply pass the page number to [getTafsirOfPage].
  ///
  Future<List<TafsirTableData>> getTafsirOfPage(
          {required int pageNumber, String? databaseName}) async =>
      await TafsirCtrl.instance
          .fetchTafsirPage(pageNumber, databaseName: databaseName!);

  /// [hafsStyle] هو النمط الافتراضي للقرآن، مما يضمن عرض جميع الأحرف الخاصة بشكل صحيح.
  ///
  /// [hafsStyle] is the default style for Quran so all special characters will be rendered correctly
  final hafsStyle = const TextStyle(
    color: Colors.black,
    // fontSize: 23.55,
    fontFamily: "hafs",
    package: "quran_library",
  );

  /// [naskhStyle] هو النمط الافتراضي للنصوص الآخرى.
  ///
  /// [naskhStyle] is the default style for other text.
  final naskhStyle = const TextStyle(
    color: Colors.black,
    fontSize: 23.55,
    fontFamily: "naskh",
    package: "quran_library",
  );

  /// [cairoStyle] هو النمط الافتراضي للنصوص الآخرى.
  ///
  /// [cairoStyle] is the default style for other text.
  final cairoStyle = const TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontFamily: "cairo",
    package: "quran_library",
  );

  /// مسح ذاكرة التخزين المؤقت لمفتاح معين أو ذاكرة التخزين المؤقت بالكامل
  /// Clear cache for specific key or entire cache
  void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }

  ///Singleton factory
  static final QuranLibrary _instance = QuranLibrary._internal();

  /// Factory constructor for creating a new instance of [QuranLibrary].
  ///
  /// This constructor is used to create an instance of the [QuranLibrary] class.
  factory QuranLibrary() {
    return _instance;
  }

  QuranLibrary._internal();
}
