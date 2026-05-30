import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'feature_registry.dart';
import 'api_client.dart';
import 'theme.dart';
import 'widgets/desktop_nav.dart';
import 'widgets/mobile_nav.dart';
import 'widgets/input_curtain.dart';
import 'widgets/carousel_viewport.dart';
import 'widgets/radial_dial.dart';
import 'database/preferences_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _idx = 0; bool _cur = false; late final List<FeatureItem> _feats;
  final _pageCtrl = PageController();

  @override void initState() {
    super.initState();
    if (Platform.isAndroid) SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(systemNavigationBarColor: OLEDTheme.bg, statusBarColor: Colors.transparent));
    _feats = FeatureRegistry.buildRegistry(null, ApiClient(baseUrl: 'http://localhost:8080'));
  }
  @override void dispose() { _pageCtrl.dispose(); super.dispose(); }

  void _onNav(int i) {
    setState(() => _idx = i);
    _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  @override Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return GestureDetector(
      onPanUpdate: (d) => setState(() => _cur = d.delta.dy > 10 ? true : (d.delta.dy < -10 ? false : _cur)),
      child: Scaffold(
        backgroundColor: OLEDTheme.bg,
        body: ListenableBuilder(listenable: PreferencesService.navProfile, builder: (_, __) => Stack(children: [
          wide ? Row(children: [DesktopNavigationRail(selectedIndex: _idx, onSelected: _onNav, features: _feats), Expanded(child: CarouselViewport(controller: _pageCtrl, features: _feats, onPageChanged: (i) => setState(() => _idx = i)))])
               : CarouselViewport(controller: _pageCtrl, features: _feats, onPageChanged: (i) => setState(() => _idx = i)),
          InputCurtain(isOpen: _cur, onClose: () => setState(() => _cur = false)),
          if (!wide && PreferencesService.navProfile.value == 'Dial') Positioned.fill(child: RadialDial(pageController: _pageCtrl)),
          if (!wide) Positioned(bottom: 0, left: 0, right: 0, child: MobileNavigationBar(selectedIndex: _idx, onSelected: _onNav, features: _feats)),
        ])),
      ),
    );
  }
}
