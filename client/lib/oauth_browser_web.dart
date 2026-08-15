import 'dart:convert';
import 'package:web/web.dart' as web;

// ponytail: web-only OAuth helpers — localStorage holds the JWT the daemon
// drops after the OAuth callback, and navigation happens in the browser.

String? oauthReadToken() => web.window.localStorage.getItem('lifeos_token');

void oauthClearToken() {
  web.window.localStorage.removeItem('lifeos_token');
}

void oauthStart(String provider, String baseUrl) {
  web.window.location.assign('$baseUrl/api/v1/auth/oauth/$provider/start');
}

List<String> oauthProvidersFromJson(String body) {
  final decoded = jsonDecode(body) as List;
  return decoded.cast<String>();
}
