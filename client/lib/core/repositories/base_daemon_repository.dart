import 'dart:async';

/// Base daemon repository that polls a daemon `GET` endpoint periodically into a notifier.
abstract class DaemonRepository {
  DaemonRepository({Duration pollInterval = const Duration(seconds: 10)}) {
    load();
    _timer = Timer.periodic(pollInterval, (_) => load());
  }

  Timer? _timer;

  Future<void> load();

  void dispose() {
    _timer?.cancel();
  }
}
