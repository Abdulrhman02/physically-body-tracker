import 'package:flutter/material.dart';
import 'screens/body_screen.dart';
import 'screens/inbody_screen.dart';
import 'screens/prompt_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/weight_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const BodyTrackerApp());

class BodyTrackerApp extends StatelessWidget {
  const BodyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Body Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _i = 0;

  static const _titles = ['Body', 'Weight', 'InBody', 'Prompt', 'Settings'];
  final _pages = const [
    BodyScreen(),
    WeightScreen(),
    InBodyScreen(),
    PromptScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('akti',
              style: TextStyle(fontWeight: FontWeight.w300)),
          const Text('BODY',
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: AppTheme.accent)),
          const SizedBox(width: 12),
          Text('· ${_titles[_i]}',
              style: const TextStyle(fontSize: 14, color: Colors.white70)),
        ]),
      ),
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.accessibility_new), label: 'Body'),
          NavigationDestination(
              icon: Icon(Icons.monitor_weight), label: 'Weight'),
          NavigationDestination(
              icon: Icon(Icons.analytics), label: 'InBody'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome), label: 'Prompt'),
          NavigationDestination(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
