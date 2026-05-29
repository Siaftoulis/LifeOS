import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _idx = 0;
  @override void initState() {
    super.initState();
    if (Platform.isAndroid) SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(systemNavigationBarColor: Colors.black));
  }

  @override Widget build(BuildContext context) {
    final bg = Platform.isAndroid ? Colors.black : const Color(0xFF0F1115);
    final views = [const Center(child: Text('Habits Stub')), const Center(child: Text('Hyper-V Stub')), const Center(child: Text('DevDocs Stub'))];
    return Scaffold(
      backgroundColor: bg,
      body: LayoutBuilder(builder: (_, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final body = isDesktop ? Row(key: const ValueKey('d'), children: [
          NavigationRail(backgroundColor: bg, unselectedIconTheme: const IconThemeData(color: Colors.grey), selectedIconTheme: const IconThemeData(color: Colors.white), selectedIndex: _idx, onDestinationSelected: (i) => setState(() => _idx = i), destinations: const [
            NavigationRailDestination(icon: Icon(Icons.check_circle), label: Text('Habits')),
            NavigationRailDestination(icon: Icon(Icons.dns), label: Text('VMs')),
            NavigationRailDestination(icon: Icon(Icons.book), label: Text('Docs'))
          ]),
          Expanded(child: views[_idx])
        ]) : Container(key: const ValueKey('m'), child: views[_idx]);
        return AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: body);
      }),
      bottomNavigationBar: MediaQuery.of(context).size.width < 900 ? BottomNavigationBar(
        backgroundColor: bg, unselectedItemColor: Colors.grey, selectedItemColor: Colors.white, currentIndex: _idx, onTap: (i) => setState(() => _idx = i),
        items: const [BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Habits'), BottomNavigationBarItem(icon: Icon(Icons.dns), label: 'VMs'), BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Docs')]
      ) : null,
    );
  }
}
