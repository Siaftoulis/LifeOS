import 'package:flutter/material.dart';
import 'app_skin_manager.dart';

abstract class EverforestColors {
  static Color get bg0 => AppSkinManager.currentSkin.bg0;
  static Color get bg1 => AppSkinManager.currentSkin.bg1;
  static Color get bg2 => AppSkinManager.currentSkin.bg2;
  static Color get fg => AppSkinManager.currentSkin.fg;

  static Color get green => AppSkinManager.currentSkin.green;
  static Color get red => AppSkinManager.currentSkin.red;
  static Color get yellow => AppSkinManager.currentSkin.yellow;
  static Color get blue => AppSkinManager.currentSkin.blue;
  static Color get purple => AppSkinManager.currentSkin.purple;
  static Color get aqua => AppSkinManager.currentSkin.aqua;
  static Color get orange => AppSkinManager.currentSkin.orange;
  static Color get cyan => AppSkinManager.currentSkin.cyan;
  static Color get grey => AppSkinManager.currentSkin.grey;

  static Color get accent => AppSkinManager.currentSkin.accent;
  static Color get textMuted => AppSkinManager.currentSkin.textMuted;
}
