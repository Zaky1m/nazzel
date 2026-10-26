import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/strings.dart';
import 'core/theme.dart';
import 'engine/engine_api.dart';
import 'ui/downloads_page.dart';
import 'ui/home_page.dart';
import 'ui/settings_page.dart';

class NazzelApp extends StatelessWidget {
  const NazzelApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: S.appName,
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: buildTheme(NzPalette.light, Brightness.light),
    darkTheme: buildTheme(NzPalette.dark, Brightness.dark),
    themeMode: ThemeMode.system,
    home: const Shell(),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    EngineApi.instance.askNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.nz;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(onStarted: () => setState(() => _index = 1), onOpenSettings: () => setState(() => _index = 2)),
          const DownloadsPage(),
          SettingsPage(active: _index == 2),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: p.bg,
          indicatorColor: p.raise,
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => TextStyle(
              fontSize: 11.5,
              fontFamily: 'IBMPlexSansArabic',
              color: s.contains(WidgetState.selected) ? p.accent : p.mute,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.accent : p.mute, size: 22),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: S.home,
            ),
            NavigationDestination(
              icon: Icon(Icons.download_outlined),
              selectedIcon: Icon(Icons.download_rounded),
              label: S.downloads,
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: S.settings,
            ),
          ],
        ),
      ),
    );
  }
}
