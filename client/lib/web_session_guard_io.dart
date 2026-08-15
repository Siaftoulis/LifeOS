// ponytail: native builds never auto-logout — local machine = trusted session
import 'package:flutter/foundation.dart';

class WebSessionGuard {
  WebSessionGuard({required this.onExpire});
  final VoidCallback onExpire;

  void attach() {}

  void detach() {}
}
