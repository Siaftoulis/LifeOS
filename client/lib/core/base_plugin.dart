import 'package:flutter/material.dart';
import '../api_client.dart';

abstract class BasePlugin {
  String get pluginId;
  String get title;
  IconData get icon;
  Widget buildView(BuildContext context);
  Future<void> initialize(dynamic db, ApiClient api);
}
