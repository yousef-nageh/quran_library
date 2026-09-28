# Fork changes (read before merging upstream)

This fork of [alheekmahlib/quran_library](https://github.com/alheekmahlib/quran_library):

1. **has no audio and no tasmee** (recitation checking with the microphone), and
2. **does not bundle the data**: the JSON files and the QCF4 fonts are downloaded
   from this repo through jsDelivr, so the package stays small.

Everything else comes from upstream.

## How to merge a new upstream version

```bash
tool/merge_upstream.sh          # merges upstream/main, never commits
```

The script deletes the removed features again and resolves the known
conflicts. Then it lists what is left and runs analyze and the tests.
Resolve what is left using the table below, then `git commit`.

**After merging, push the data too.** If upstream added or changed files in
`assets/jsons/`, `assets/*.json.gz` or `assets/fonts/quran_fonts_qfc4/`, they
are served from this repo's `main` branch. If a JSON file changed, bump
`QuranRemoteAssets.dataVersion` so users download it again.

## Fork-owned files (upstream never has these, so they never conflict)

| File | What it does |
|---|---|
| `lib/src/services/quran_remote_assets.dart` | Loads `packages/quran_library/assets/...` from the CDN (`cdnBaseUrl` + same path). Retries network errors (`retryDelays`) and only accepts complete files (Content-Length + gzip CRC32/size trailer check), so a cut download is never cached. `dataVersion` clears the JSON cache when the server data changes. |
| `lib/src/services/quran_downloader.dart` | `ensureInitialized()` downloads the startup JSON files; each is checked to be valid JSON and a broken cached copy is deleted and downloaded again. Files that finished stay cached, so a retry only downloads the missing ones. `loadJson(name)` is also available. |
| `lib/src/services/isolate_service.dart` | Parses the Quran data on a background isolate. |
| `lib/src/services/quran_ctrl_fast_loading.dart` | `loadQuranDataV3InBackground()` / `fetchSurahsInBackground()`. **Mirrors upstream's `QuranCtrl.loadQuranDataV3()`**: after a merge, copy any new steps from upstream into it (the script shows the upstream diff). |
| `lib/src/pages/quran_library_screen_future.dart` | Loading screen: version check, `init`, download, and prepare. |
| `tool/merge_upstream.sh`, `FORK_CHANGES.md` | This process. |

## Edits inside upstream files (keep these when resolving)

Each fork edit is marked with a `// fork:` comment where possible.

| Upstream file | Fork edit | On conflict |
|---|---|---|
| `lib/src/service/gzip_json_asset_service_io.dart` | `rootBundle.load` → `QuranRemoteAssets.load` (+ its import); `_writeToDisk` writes a `.tmp` file then renames it (no half-written cache if the app is killed) | take upstream, re-apply these lines |
| `lib/src/quran/core/services/quran_fonts_service.dart` | `rootBundle.load` → `QuranRemoteAssets.load` in `_decompressFromAsset`, and `_pageLoadFutures.remove(page)` in the catch of `_loadSinglePage` | take upstream, re-apply the 2 lines |
| `lib/src/pages/quran_library_screen.dart` | `build()` wraps in `QuranLibraryScreenFuture` and calls `_buildScreen` (upstream's `build` body, renamed). Audio slider, tasmee control, audio styles and params removed. | take upstream, rename `build`→`_buildScreen`, re-add the wrapper, delete audio/tasmee |
| `lib/src/flutter_quran_utils.dart` | `init()` doesn't load the data. `prepareQuranScreen()` added (calls the fast loading). The audio/word-audio API is removed. | take upstream, move the data loading out of `init`, delete audio members |
| `lib/src/quran/presentation/controllers/quran/quran_getters.dart` | Bounds-safe `getPageAyahsByIndex`, `orElse` in `getSurahDataByAyahUQ`, `&&` fix in `isThereAnySajdaInPage`, no audio in `showControlToggle` | keep the fork's lines |
| `lib/src/quran/presentation/widgets/tabs/quran_top_bar.dart` | No audio/tasmee buttons. `_MenuBottomSheet.build` wraps in `Directionality` (RTL for `ar`) and calls `_buildSheet`. | take upstream, re-apply |
| `lib/src/core/theme/quran_library_theme.dart` | No `AyahDownloadManagerTheme` (replaced by `KeyedSubtree` to keep indentation), no `TasmeeTheme` | delete audio/tasmee |
| `lib/src/pages/quran_pages_screen.dart`, `surah_display_screen.dart` | Audio slider, audio styles, tasmee removed | delete audio/tasmee |
| `lib/src/quran/presentation/widgets/ayah_menu_dialog.dart`, `display_modes/ayah_with_tafsir_inline.dart` | Play buttons removed | delete audio |
| `lib/src/quran/presentation/controllers/word_info/word_info_ctrl.dart`, `widgets/word_info/word_info_bottom_sheet.dart` | Word audio removed | delete audio |
| `lib/src/quran/data/models/styles_models/ayah_menu_style.dart`, `quran_top_bar_style.dart` | Play/audio/tasmee options removed | delete audio/tasmee |
| `lib/src/quran/presentation/widgets/download_fonts_page/custom_span.dart`, `qpc_v4_flowing_text.dart`, `rich_text_build.dart` | Kept at the **pre-tasmee** upstream version (`c059a98^1`), because every later upstream change to them was tasmee | take upstream and remove the tasmee code, or keep the fork's version if the upstream change is tasmee-only |
| `lib/src/quran/presentation/widgets/auto_scroll/auto_scroll_speed_slider.dart` | `CustomWidgets.customSvgWithColor` (from audio) → `SvgPicture.asset` | re-apply |
| `lib/src/core/widgets/patched_preload_page_view.dart` | `scrollCacheExtent: ScrollCacheExtent.pixels(..)` → `cacheExtent:` (needed for Flutter 3.41) | can drop once the Flutter SDK is upgraded |
| `lib/quran.dart`, `lib/quran_library.dart` | No audio/tasmee imports, parts and exports. The fork's services are imported, and `quran_library_screen_future.dart` and `quran_ctrl_fast_loading.dart` are parts. `QuranDownloader` is exported. | take upstream's new parts, keep the fork's lines |
| `pubspec.yaml` | No `audio_service`, `just_audio*`, `record`, `sherpa_onnx*`. `assets:` bundles only fonts/svg/images (no `jsons`, `quran_fonts_qfc4`, `quran_lab`, or root `*.json.gz`). | automatic: the script takes upstream's file and strips these lines (also the `surahName` font family, whose font file the fork deleted) |
| `android/src/main/AndroidManifest.xml`, `example/ios/Runner/Info.plist`, `example/macos/Runner/*.entitlements` | No audio service or microphone permissions | keep ours |
| `test/quran_fonts_service_cache_version_test.dart` | Sets `QuranRemoteAssets.debugLoader` to read the repo's font files | re-apply the 3 lines |

## Assets

The repo keeps **the same `assets/` layout as upstream** (the CDN path equals the
asset path). The old `assets/jsons/{en,saadi,quranV3,quran_hafs}.json.gz` are kept
for app versions released before this layout.
