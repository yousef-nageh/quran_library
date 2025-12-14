## Quran Library
<p align="center">
<img src="https://raw.githubusercontent.com/alheekmahlib/thegarlanded/master/Photos/Packages/quran_library/quran_library_banner.png" width="500"/>
</p>


<!-- الصف الأول -->
<p align="center">
  <a href="https://pub.dev/packages/quran_library">
    <img alt="pub package" src="https://img.shields.io/pub/v/quran_library.svg?color=2cacbf&labelColor=145261" />
  </a>
  <a href="https://pub.dev/packages/quran_library/score">
    <img alt="pub points" src="https://img.shields.io/pub/points/quran_library?color=2cacbf&labelColor=145261" />
  </a>
  <a href="https://pub.dev/packages/quran_library/score">
    <img alt="likes" src="https://img.shields.io/pub/likes/quran_library?color=2cacbf&labelColor=145261" />
  </a>
  <a href="https://pub.dev/packages/quran_library/score">
    <img alt="Pub Downloads" src="https://img.shields.io/pub/dm/quran_library?color=2cacbf&labelColor=145261" />
  </a>
  <a href="LICENSE">
    <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-2cacbf.svg?labelColor=145261" />
  </a>
</p>

<!-- الصف الثاني -->
<p align="center">
  <a href="https://flutter.dev/">
    <img alt="Web" src="https://img.shields.io/badge/Web-145261?logo=google-chrome&logoColor=white" />
  </a>
  <a href="https://flutter.dev/">
    <img alt="Windows" src="https://img.shields.io/badge/Windows-145261?logo=Windows&logoColor=white" />
  </a>
  <a href="https://flutter.dev/">
    <img alt="macOS" src="https://img.shields.io/badge/macOS-145261?logo=apple&logoColor=white" />
  </a>
  <a href="https://flutter.dev/">
    <img alt="Android" src="https://img.shields.io/badge/Android-145261?logo=android&logoColor=white" />
  </a>
  <a href="https://flutter.dev/">
    <img alt="iOS" src="https://img.shields.io/badge/iOS-145261?logo=ios&logoStyle=bold&logoColor=white" />
  </a>
</p>


<p align="center"><strong>Choose your language for the documentation:</strong></p>

<p align="center">
  <a href="https://alheekmahlib.github.io/quran_library_web/#/ar" ><img alt="Arabic" src="https://img.shields.io/badge/Arabic-2cacbf?size-30" height="30" /></a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/en" ><img alt="English" src="https://img.shields.io/badge/English-2cacbf?size-30" height="30" /></a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/bn" ><img alt="bangla" src="https://img.shields.io/badge/bangla-2cacbf?size-30" height="30" /></a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/id" ><img alt="Bahasa Indonesia" src="https://img.shields.io/badge/Bahasa Indonesia-2cacbf?size-30" height="30" /></a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/ur" ><img alt="Urdu" src="https://img.shields.io/badge/Urdu-2cacbf?size-30" height="30" /></a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/tr" ><img alt="Türkçe" src="https://img.shields.io/badge/Türkçe-2cacbf?size-30" height="30" /></a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/ku" ><img alt="Kurdish" src="https://img.shields.io/badge/Kurdish-2cacbf?size-30" height="30" /></a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/ms" ><img alt="Bahasa Malaysia" src="https://img.shields.io/badge/Bahasa Malaysia-2cacbf?size-30" height="30" /></a>
  <a href="https://alheekmahlib.github.io/quran_library_web/#/es" ><img alt="Español" src="https://img.shields.io/badge/Español-2cacbf?size-30" height="30" /></a>
</p>


### Important note before starting to use: Please make:
```dart
  useMaterial3: false,
```
### In order not to cause any formation problems

#

## Table of Contents

- [Getting started](#getting-started)
- [Usage Example](#usage-example)
  - [Basic Quran Screen](#basic-quran-screen)
  - [Individual Surah Display](#individual-surah-display)
  - [Single Ayah Display](#single-ayah-display)
  - [Partial Pages (single or range) + Highlighting](#partial-pages-single-or-range--highlighting)
- [Utils](#utils)
  - [Getting all Quran's Jozzs, Hizbs, and Surahs](#getting-all-qurans-jozzs-hizbs-and-surahs)
  - [to jump between pages, Surahs or Hizbs you can use](#to-jump-between-pages-surahs-or-hizbs-you-can-use)
  - [Adding, setting, removing, getting and navigating to bookmarks](#adding-setting-removing-getting-and-navigating-to-bookmarks)
  - [searching for any Ayah](#searching-for-any-ayah)
- [Fonts Download](#fonts-download)
- [Tafsir](#tafsir)
- [Sources](#sources)
- [License](#license)

#

## Getting started

**No special configuration required!**
This package assumes a "plug-and-play" philosophy. We've removed all complex audio configuration (and the audio retrieval feature itself), so you don't need to touch `AndroidManifest.xml` or `Info.plist` anymore.

### Optimized Data Loading with Smart Initialization
The heavy Quran JSON assets are now **compressed** and downloaded on-demand from our git server. This drastically reduces your app's initial download size.

**The library handles absolutely everything for you.** When you use the `QuranLibraryScreen`, it automatically checks for assets, downloads/decompresses them if needed, and loads the data into memory.

In the `pubspec.yaml` of your flutter project, add the following dependency:

```yaml
dependencies:
  ...
  quran_library: ^2.3.2
```

Import it:

```dart
import 'package:quran_library/quran_library.dart';
```

**That's it! Just run your app:**

```dart
Future<void> main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const MyApp(),
  );
}
```

### Optional: Pre-loading (Performance Optimization)
If you prefer to load the data *before* the user opens the Quran screen (to avoid a loading spinner on the first open), you can (optionally) call the initialization methods in your `main()` function:

```dart
Future<void> main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  
  // Optional: Start  set local storage path and download fonts
  await QuranLibrary.init();
  // Optional: download all quran json 
  await QuranDownloader.ensureInitialized();
  // Optional: Load data into memory immediately using isolate for better performance
  await QuranLibrary.prepareQuranScreen();
  
  runApp(const MyApp());
}
```

## Usage Example

### Basic Quran Screen

Just drop the widget into your code. It will handle the loading automatically!

```dart
/// You can just add it to your code like this:
class MyQuranPage extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return QuranLibraryScreen(
      parentContext: context, // Required
    );
  }
}
```


#### or give it some options:

```dart
QuranLibraryScreen(
            parentContext: context,
            withPageView: true,
            useDefaultAppBar: true,
            // isShowAudioSlider: false, // REMOVED: Audio features are gone
            showAyahBookmarkedIcon: false,
            isDark: isDark,
            appLanguageCode: Get.locale!.languageCode,
            backgroundColor: context.theme.colorScheme.surface,
            textColor: context.textDarkColor,
            ayahSelectedBackgroundColor:
                context.theme.colorScheme.primary.withValues(alpha: .2),
            ayahIconColor: context.theme.colorScheme.primary,
            surahInfoStyle:
                SurahInfoStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              ayahCount: 'aya_count'.tr,
              firstTabText: 'surahNames'.tr,
              secondTabText: 'aboutSurah'.tr,
              bottomSheetWidth: 500,
            ),
            basmalaStyle: BasmalaStyle(
              verticalPadding: 0.0,
              basmalaColor: context.textDarkColor.withValues(alpha: .8),
              basmalaFontSize: isLoadedFont ? 120.0 : 25.0,
            ),
            ayahStyle: AyahAudioStyle.defaults(isDark: isDark, context: context)
                .copyWith(
              dialogWidth: 300,
              readersTabText: 'readers'.tr,
            ),
            topBarStyle:
                QuranTopBarStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              // showAudioButton: false, // REMOVED
              showFontsButton: false,
              tabIndexLabel: 'index'.tr,
              tabBookmarksLabel: 'bookmarks'.tr,
              tabSearchLabel: 'search'.tr,
            ),
            indexTabStyle:
                IndexTabStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              tabSurahsLabel: 'surahs'.tr,
              tabJozzLabel: 'juzz'.tr,
            ),
            searchTabStyle:
                SearchTabStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              searchHintText: 'search'.tr,
            ),
            bookmarksTabStyle:
                BookmarksTabStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              emptyStateText: 'no_bookmarks_yet'.tr,
              greenGroupText: 'greenBookmarks'.tr,
              yellowGroupText: 'yellowBookmarks'.tr,
              redGroupText: 'redBookmarks'.tr,
            ),
            ayahMenuStyle:
                AyahMenuStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              copySuccessMessage: 'ayah_copied'.tr,
              showPlayAllButton: false,
            ),
            tafsirStyle:
                TafsirStyle.defaults(isDark: isDark, context: context).copyWith(
              widthOfBottomSheet: 500,
              heightOfBottomSheet: MediaQuery.sizeOf(context).height * 0.9,
              changeTafsirDialogHeight: MediaQuery.sizeOf(context).height * 0.9,
              changeTafsirDialogWidth: 400,
              tafsirNameWidget: customSvgWithCustomColor(
                'assets/svg/tafseer_white.svg',
                color: context.theme.colorScheme.primary,
                height: 24,
              ),
              tafsirName: 'tafsir'.tr,
              translateName: 'translate'.tr,
              tafsirIsEmptyNote: 'tafsirIsEmptyNote'.tr,
              footnotesName: 'footnotes'.tr,
            ),
            topBottomQuranStyle: TopBottomQuranStyle.defaults(
              isDark: isDark,
              context: context,
            ).copyWith(
              hizbName: 'hizb'.tr,
              juzName: 'juz'.tr,
              sajdaName: 'sajda'.tr,
            ),
          ),
```

### Individual Surah Display

<details>
<summary>Expand section</summary>


```dart
/// For displaying a single surah with custom pagination
SurahDisplayScreen(
  /// [surahNumber] The surah number to display
  surahNumber: 1, // For Al-Fatihah
  /// [onPageChanged] if provided it will be called when a surah page changed
  onPageChanged: (int pageIndex) => print("Surah page changed: $pageIndex"),
  /// [isDark] enable or disable dark mode
  isDark: false,
  /// [basmalaStyle] Change the style of Basmala
  basmalaStyle: BasmalaStyle.defaults(
              isDark: isDark,
              context: context,
            ).copyWith(
    basmalaColor: Colors.black,
    basmalaWidth: 160.0,
    basmalaHeight: 30.0,
  ),
  /// [bannerStyle] Change the style of banner
  bannerStyle: BannerStyle.defaults(
              isDark: isDark,
              context: context,
            ).copyWith(
    isImage: false,
    bannerSvgHeight: 40.0,
    bannerSvgWidth: 150.0,
  ),
  /// and more options...
),
```

</details>

### Single Ayah Display

<details>
<summary>Expand section</summary>


```dart
/// For displaying a single ayah from any surah
GetSingleAyah(
  /// [surahNumber] - must be between 1 and 114
  surahNumber: 1, // Surah number
    
  /// [ayahNumber] - ayah number within the surah
  ayahNumber: 2, // Ayah number
    
  /// [textColor] - optional text color
  textColor: Colors.black,
    
  /// [isDark] - optional, default is false
  isDark: false,
    
  /// [fontSize] - optional, default is 22
  fontSize: 24.0,
    
  /// [isBold] - optional, default is true
  isBold: true,
),
```

</details>

### Partial Pages (single or range) + Highlighting

<details>
<summary>Expand section</summary>

You can display just one specific page or a range of pages using `QuranPagesScreen`.

Requirements:
- Pass the parent widget context via `parentContext`.
- Choose either a single `page` or a range using `startPage` and `endPage`.

Basic examples:

```dart
// Single page
QuranPagesScreen(
  parentContext: context,
  page: 6,
)

// Range of pages (inclusive)
QuranPagesScreen(
  parentContext: context,
  startPage: 6,
  endPage: 11,
)

// Optional: disable page view if you want a static view
QuranPagesScreen(
  parentContext: context,
  startPage: 6,
  endPage: 7,
  withPageView: false,
)
```

Programmatic highlighting (by surah/ayah numbers):

```dart
// Highlight by Surah and Ayah numbers
QuranPagesScreen(
  parentContext: context,
  page: 6,
  highlightedAyahNumbersBySurah: {
    18: [1, 5, 10], // Surah Al-Kahf: ayahs 1,5,10
    36: [3],        // Surah Ya-Sin: ayah 3
  },
)

// Highlight by page range + ayah numbers (within those pages)
QuranPagesScreen(
  parentContext: context,
  startPage: 6,
  endPage: 11,
  highlightedAyahNumbersInPages: [
    (start: 6, end: 11, ayahs: [1, 3, 5]),
  ],
)

// If you already have unique ayah numbers (UQ), you can still pass them directly
QuranPagesScreen(
  parentContext: context,
  page: 6,
  highlightedAyahs: [1023, 1024, 1025],
)
```

Optional multi-select mode (keeps multiple ayahs selected on long-press):

```dart
QuranPagesScreen(
  parentContext: context,
  page: 6,
  enableMultiSelect: true,
)
```

Notes:
- `QuranPagesScreen` is a StatelessWidget.
- Highlighting is applied programmatically and does not replace manual selection.
- You can combine multiple highlighting inputs; they’ll be merged internally.

</details>

#### Using GetSingleAyah in a list:

<details>
<summary>Expand section</summary>


```dart
class SingleAyahExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display Single Ayahs')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Ayat al-Kursi
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Ayat al-Kursi', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  GetSingleAyah(
                    surahNumber: 2, // Al-Baqarah
                    ayahNumber: 255, // Ayat al-Kursi
                    fontSize: 20,
                    textColor: Colors.brown,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Complete Al-Fatihah
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Surah Al-Fatihah', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  // Display all ayahs of Al-Fatihah
                  ...List.generate(7, (index) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: GetSingleAyah(
                      surahNumber: 1,
                      ayahNumber: index + 1,
                      fontSize: 18,
                      isDark: false,
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

</details>

## Utils

### The package provides a lot of utils like:

* ### Getting all Quran's Jozzs, Hizbs, and Surahs

```dart
final jozzs = QuranLibrary.allJoz;
final hizbs = QuranLibrary.allHizb;
final surahs = QuranLibrary.getAllSurahs();
final ayahsOnPage = QuranLibrary().getAyahsByPage();

/// [getSurahInfo] let's you get a Surah with all its data when you pass Surah number
final surah = QuranLibrary().getSurahInfo(1);
```

* ### to jump between pages, Surahs or Hizbs you can use:
```dart
/// [jumpToAyah] let's you navigate to any ayah..
/// It's better to call this method while Quran screen is displayed
/// and if it's called and the Quran screen is not displayed, the next time you
/// open quran screen it will start from this ayah's page
QuranLibrary().jumpToAyah(AyahModel ayah);
/// or you can use:
/// jumpToPage, jumpToJoz, jumpToHizb, jumpToBookmark and jumpToSurah.
```

<img src="https://raw.githubusercontent.com/alheekmahlib/thegarlanded/master/Photos/Packages/quran_library/archive_screen.png" width="320"/>

* ### Adding, setting, removing, getting and navigating to bookmarks:

```dart
// In init function
QuranLibrary().init(userBookmarks: [Bookmark(id: 0, colorCode: Colors.red.value, name: "Red Bookmark")]);
final usedBookmarks = QuranLibrary().getUsedBookmarks();
QuranLibrary().setBookmark(surahName: 'Al-Fatihah', ayahNumber: 5, ayahId: 5, page: 1, bookmarkId: 0);
QuranLibrary().removeBookmark(bookmarkId: 0);
QuranLibrary().jumpToBookmark(BookmarkModel bookmark);
```

<img src="https://raw.githubusercontent.com/alheekmahlib/thegarlanded/master/Photos/Packages/quran_library/bookmark_screen2.png" width="320"/> <img src="https://raw.githubusercontent.com/alheekmahlib/thegarlanded/master/Photos/Packages/quran_library/bookmark_screen.png" width="320"/>

* ### searching for any Ayah
```dart
TextField(
  onChanged: (txt) {
    final _ayahs = QuranLibrary().search(txt);
      setState(() {
        ayahs = [..._ayahs];
      });
  },
  decoration: InputDecoration(
    border:  OutlineInputBorder(borderSide: BorderSide(color: Colors.black),),
    hintText: 'Search',
  ),
),
```
<img src="https://raw.githubusercontent.com/alheekmahlib/thegarlanded/master/Photos/Packages/quran_library/search_screen.png" width="320"/>

## Fonts Download

## To download Quran fonts, you have two options:
* ### As for using the default dialog, you can modify the style in it.
* ### Or you can create your own design using all the functions for downloading fonts.

## macOS needs you to request a specific entitlement in order to access the network. 
### To do that: open macos/Runner/DebugProfile.entitlements and add the following key-value pair.

```xml
<key>com.apple.security.network.client</key>
<true/>
```

```dart
///
/// to get the fonts download dialog just call [getFontsDownloadDialog]
///
/// and pass the language code to translate the number if you want,
/// the default language code is 'ar' [languageCode]
/// and style [DownloadFontsDialogStyle] is optional.
QuranLibrary().getFontsDownloadDialog(downloadFontsDialogStyle, languageCode);

/// to get the fonts download widget just call [getFontsDownloadWidget]
Widget getFontsDownloadWidget(context, {downloadFontsDialogStyle, languageCode});

/// to get the fonts download method just call [fontsDownloadMethod]
QuranLibrary().fontsDownloadMethod;

/// to prepare the fonts was downloaded before just call [getFontsPrepareMethod]
/// required to pass [pageIndex]
QuranLibrary().getFontsPrepareMethod(pageIndex);

/// to delete the fonts just call [deleteFontsMethod]
QuranLibrary().deleteFontsMethod;

/// to get fonts download progress just call [fontsDownloadProgress]
QuranLibrary().fontsDownloadProgress;

/// To find out whether fonts are downloaded or not, just call [isFontsDownloaded]
QuranLibrary().isFontsDownloaded;
```

<img src="https://raw.githubusercontent.com/alheekmahlib/thegarlanded/master/Photos/Packages/quran_library/font_download_screen.png" width="320"/>

## Tafsir

* ### Usage Example

```dart
// get current list


final all = TafsirController.instance.items; // includes defaults + customs

// add a custom sql file (File is from file picker)

final added = await TafsirController.instance.addCustomFromFile(

  sourceFile: pickedFile,

  displayName: 'My Custom Tafsir',

  bookName: 'My Book',

  type: TafsirFileType.json,

);
/// Show a popup menu to change the tafsir style.
QuranLibrary().changeTafsirPopupMenu(TafsirStyle tafsirStyle, {int? pageNumber});

/// Fetch tafsir for a specific page by its page number.
QuranLibrary().fetchTafsir({required int pageNumber});

/// Check if the tafsir is already downloaded.
QuranLibrary().getTafsirDownloaded(int index);

/// Get the list of tafsir and translation names.
QuranLibrary().tafsirAndTraslationCollection;

/// Change the selected tafsir when the switch button is pressed.
QuranLibrary().changeTafsirSwitch(int index, {int? pageNumber});

/// Get the list of available tafsir data.
QuranLibrary().tafsirList;

/// Get the list of available translations.
QuranLibrary().translationList;

/// Fetch translations from the source.
QuranLibrary().fetchTranslation();

/// Download the tafsir by the given index.
QuranLibrary().tafsirDownload(int i);
```

<img src="https://raw.githubusercontent.com/alheekmahlib/thegarlanded/master/Photos/Packages/quran_library/tafsir_screen.png" width="320"/>

## Sources

[**King Fahd Complex**](https://qurancomplex.gov.sa/): The source of the Uthmanic text of the Qur’an for the "Hafs" narration.

[**Tafsir Center**](https://tafsir.net/): The source of the Qur’an tafsir (explanation).

## License

[**MIT License**](LICENSE)
