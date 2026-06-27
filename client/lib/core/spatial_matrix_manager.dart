import '../database/preferences_service.dart';

class SpatialMatrixManager {
  static final List<String> protectedModules = ['home', 'configurator'];

  static void dropRow() {
    final layout = PreferencesService.layout.value;
    final rows = layout.length;
    final cols = layout[0].length;
    
    if (rows > 1 && (rows - 1) * cols >= 2) {
      final List<List<String>> newLayout = layout.map((r) => List<String>.from(r)).toList();
      final rowToDrop = newLayout.last;
      
      final evicted = <String>[];
      for (final module in rowToDrop) {
        if (protectedModules.contains(module)) {
          evicted.add(module);
        }
      }
      
      for (final module in evicted) {
        bool relocated = false;
        // Try to find a void slot first
        for (int i = 0; i < rows - 1; i++) {
          for (int j = 0; j < newLayout[i].length; j++) {
            if (newLayout[i][j] == 'void' || newLayout[i][j] == '') {
              newLayout[i][j] = module;
              relocated = true;
              break;
            }
          }
          if (relocated) break;
        }
        
        // If no void slot, replace a non-protected module
        if (!relocated) {
          for (int i = 0; i < rows - 1; i++) {
            for (int j = 0; j < cols; j++) {
              if (!protectedModules.contains(newLayout[i][j])) {
                newLayout[i][j] = module;
                relocated = true;
                break;
              }
            }
            if (relocated) break;
          }
        }
      }
      newLayout.removeLast();
      PreferencesService.setLayout(newLayout);
    }
  }

  static void addRow() {
    final layout = PreferencesService.layout.value;
    final cols = layout[0].length;
    final List<List<String>> newLayout = layout.map((r) => List<String>.from(r)).toList();
    newLayout.add(List.filled(cols, 'void'));
    PreferencesService.setLayout(newLayout);
  }

  static void dropColumn() {
    final layout = PreferencesService.layout.value;
    final cols = layout[0].length;
    final rows = layout.length;
    
    if (cols > 1 && rows * (cols - 1) >= 2) {
      final List<List<String>> newLayout = layout.map((r) => List<String>.from(r)).toList();
      final evicted = <String>[];
      
      for (int i = 0; i < newLayout.length; i++) {
        final module = newLayout[i][cols - 1];
        if (protectedModules.contains(module)) {
          evicted.add(module);
        }
      }
      
      for (final module in evicted) {
        bool relocated = false;
        // Try void slots
        for (int i = 0; i < newLayout.length; i++) {
          for (int j = 0; j < cols - 1; j++) {
            if (newLayout[i][j] == 'void' || newLayout[i][j] == '') {
              newLayout[i][j] = module;
              relocated = true;
              break;
            }
          }
          if (relocated) break;
        }
        
        // Try replacing non-protected
        if (!relocated) {
          for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols - 1; j++) {
              if (!protectedModules.contains(newLayout[i][j])) {
                newLayout[i][j] = module;
                relocated = true;
                break;
              }
            }
            if (relocated) break;
          }
        }
      }
      
      for (final row in newLayout) {
        row.removeLast();
      }
      PreferencesService.setLayout(newLayout);
    }
  }

  static void addColumn() {
    final layout = PreferencesService.layout.value;
    final List<List<String>> newLayout = layout.map((r) => List<String>.from(r)).toList();
    for (final row in newLayout) {
      row.add('void');
    }
    PreferencesService.setLayout(newLayout);
  }
}
