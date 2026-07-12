import 'package:flutter/material.dart';
import 'theme/everforest_colors.dart';
import 'presentation/engine/spatial_engine.dart';
import 'core/dev_simulation_service.dart' as import_dev_sim;
import 'app_module_router.dart';
import 'global_keys.dart';

class SpatialEngineScaffold extends StatelessWidget {
  final List<List<String>> layout;
  final int startX;
  final int startY;

  const SpatialEngineScaffold({
    super.key,
    required this.layout,
    required this.startX,
    required this.startY,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerUp: (e) {
        import_dev_sim.DevSimulationService.onUserInteraction();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: EverforestColors.bg0,
        body: SpatialEngine(
          key: spatialEngineKey,
          layout: layout,
          startX: startX,
          startY: startY,
          builder: (moduleId, y, x) {
            return KeyedSubtree(
              key: import_dev_sim.DevSimulationService.getModuleKey('${moduleId}_${y}_$x'),
              child: AppModuleRouter.buildModule(moduleId),
            );
          },
        ),
      ),
    );
  }
}
