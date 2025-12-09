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
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // Initialize in sequence:
    // 1. Download JSON files from CDN
    // 2. Load Quran data in parallel
    _initializationFuture = _initializeQuranData();
  }

  /// Initializes Quran data in two steps:
  /// 1. Download and cache JSON files
  /// 2. Load Quran data in parallel
  Future<void> _initializeQuranData() async {
    // Step 1: Download and cache all JSON files from CDN
         await QuranLibrary.init();
    await QuranDownloader.ensureInitialized();

      await  QuranLibrary.prepareQuranScreen();


    // Step 2: Load Quran data in parallel

  }

  @override
  void dispose() {

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          return widget.errorBuilder?.call(snapshot.error!) ??
              Scaffold(
                backgroundColor: widget.backgroundColor ??
                    AppColors.getBackgroundColor(widget.isDark),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: widget.isDark ? Colors.red[300] : Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'خطأ في تحميل البيانات',
                        style: TextStyle(
                          color: widget.isDark ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                widget.isDark ? Colors.white70 : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
