import 'dart:async';
import 'package:flutter/material.dart';
import '../global_keys.dart';
import '../theme/everforest_colors.dart';
import 'event_hub.dart';

/// Live award feedback: relays `points:balance-change` from the daemon bus
/// as a global snackbar. Rate-limited to one per 30s so streaks don't spam.
class PointsLiveFeedback {
  static final PointsLiveFeedback instance = PointsLiveFeedback._();
  PointsLiveFeedback._();

  Timer? _throttle;
  StreamSubscription? _sub;

  void start() {
    if (_sub != null) return;
    _sub = EventHub.instance.on('points:balance-change').listen((e) {
      final payload = e['payload'];
      if (payload is! Map) return;
      final amount = (payload['Amount'] as num?)?.toInt() ?? 0;
      final reason = (payload['Event'] as String?)?.toString() ?? 'Points';
      if (amount == 0 || (_throttle?.isActive ?? false)) return;
      _throttle = Timer(const Duration(seconds: 30), () {});
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            '⭐ +$amount pts · ${reason.replaceFirst('Telemetry: ', '')}',
            style: const TextStyle(color: EverforestColors.fg),
          ),
          backgroundColor: EverforestColors.bg1,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
}