import 'dart:isolate';

import 'package:flutter/foundation.dart' show kIsWeb;

/// Runs [task] on a background isolate ([Isolate.run]), so heavy work
/// (gzip, JSON parsing) doesn't block the UI thread. On web, where isolates
/// aren't available, runs it directly.
///
/// [task] is sent to the other isolate: capture only local values, never
/// `this` or a controller.
Future<R> runInBackground<R>(R Function() task) =>
    kIsWeb ? Future.sync(task) : Isolate.run(task);
