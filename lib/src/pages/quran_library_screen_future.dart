part of '/quran.dart';

/// A wrapper widget that initializes QuranDownloader before displaying the child.
///
/// This widget handles downloading and caching Quran JSON files from the server
/// on first launch. On subsequent launches, it uses the cached files.
///
/// Use this widget to wrap [QuranLibraryScreen] or any other widget that depends
/// on Quran data being available.
///
/// Example:
/// ```dart
/// QuranLibraryScreenFuture(
///   child: QuranLibraryScreen(
///     parentContext: context,
///     isDark: false,
///   ),
/// )
/// ```
class QuranLibraryScreenFuture extends StatefulWidget {
  /// The child widget to display after initialization is complete.
  ///
  /// Typically this will be a [QuranLibraryScreen] widget.
  final Widget child;

  /// Optional loading widget to show during initialization.
  ///
  /// If not provided, a default loading indicator with Arabic text will be shown.
  final Widget? loadingWidget;

  /// Optional error widget builder.
  ///
  /// If not provided, a default error screen will be shown.
  final Widget Function(Object error)? errorBuilder;

  /// Background color for loading and error states.
  final Color? backgroundColor;

  /// Whether the UI is in dark mode.
  final bool isDark;

  /// Creates a wrapper that initializes Quran data before showing the child.
  const QuranLibraryScreenFuture({
    super.key,
    required this.child,
    this.loadingWidget,
    this.errorBuilder,
    this.backgroundColor,
    this.isDark = false,
  });

  @override
  State<QuranLibraryScreenFuture> createState() =>
      _QuranLibraryScreenFutureState();
}

class _QuranLibraryScreenFutureState extends State<QuranLibraryScreenFuture> {
  /// True once the data is loaded in this app run: opening the screen again
  /// shows it at once, without the loader.
  static bool _dataReady = false;

  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    if (!_dataReady) _initializationFuture = _initializeQuranData();
  }

  /// Initializes Quran data in three steps:
  /// 1. Download and cache JSON files (first launch only)
  /// 2. Load Quran data in parallel
  /// 3. Prepare the current page, so no second loader shows after this one
  Future<void> _initializeQuranData() async {
    // Clear cached JSON first if the data on the server changed
    await QuranRemoteAssets.ensureDataVersion();
    await QuranLibrary.init();

    // Step 1: Download and cache the JSON files from CDN
    await QuranDownloader.ensureInitialized();

    // Step 2: Load Quran data in parallel
    await QuranLibrary.prepareQuranScreen();

    // Step 3: Layout and fonts of the page that opens first
    await QuranCtrl.instance.prepareCurrentPageInBackground();

    _dataReady = true;
  }

  /// Tries again after a failure. Files that already downloaded are read
  /// from the cache, so only the missing ones are downloaded.
  void _retry() {
    setState(() => _initializationFuture = _initializeQuranData());
  }

  @override
  Widget build(BuildContext context) {
    if (_dataReady) return widget.child;
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // Show loading indicator while downloading JSON files
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget ??
              Scaffold(
                backgroundColor: widget.backgroundColor ??
                    AppColors.getBackgroundColor(widget.isDark),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator.adaptive(
                        backgroundColor:
                            widget.isDark ? Colors.white : Colors.black,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'تحميل بيانات القرآن...',
                        style: TextStyle(
                          color: widget.isDark ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
        }

        // Show error if initialization failed
        if (snapshot.hasError) {
          log('Quran data initialization failed: ${snapshot.error}',
              name: 'QuranLibraryScreenFuture', stackTrace: snapshot.stackTrace);
          final textColor = widget.isDark ? Colors.white : Colors.black;
          return widget.errorBuilder?.call(snapshot.error!) ??
              Scaffold(
                backgroundColor: widget.backgroundColor ??
                    AppColors.getBackgroundColor(widget.isDark),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 64,
                          color: widget.isDark ? Colors.red[300] : Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'تعذر تحميل بيانات القرآن',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تحقق من الاتصال بالإنترنت ثم أعد المحاولة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
        }

        // Data is ready, show the child widget
        return widget.child;
      },
    );
  }
}
