import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/ui/logout/logout_page.dart';

class LogoutApp extends StatefulWidget {
  const LogoutApp({super.key});

  @override
  State<LogoutApp> createState() => _LoginAppState();
}

class _LoginAppState extends State<LogoutApp> {
  final delegate = LogoutRouterDelegate();

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xff769e57),
        dynamicSchemeVariant: DynamicSchemeVariant.neutral,
      ),
    );
    final darkTheme = ThemeData(
      colorScheme: theme.colorScheme.copyWith(brightness: Brightness.dark),
      brightness: Brightness.dark,
    );
    return MaterialApp.router(
      title: 'Login | Phylum',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      routeInformationParser: const LogoutRouteInformationParser(),
      routerDelegate: delegate,
    );
  }
}

class LogoutRouteConfiguration {
  const LogoutRouteConfiguration();
}

class LogoutRouteInformationParser extends RouteInformationParser<LogoutRouteConfiguration> {
  const LogoutRouteInformationParser();

  @override
  Future<LogoutRouteConfiguration> parseRouteInformation(RouteInformation routeInformation) {
    return SynchronousFuture(const LogoutRouteConfiguration());
  }

  @override
  RouteInformation? restoreRouteInformation(LogoutRouteConfiguration configuration) {
    return RouteInformation(uri: Uri(path: '/logout'));
  }
}

class LogoutRouterDelegate extends RouterDelegate<LogoutRouteConfiguration>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<LogoutRouteConfiguration> {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  LogoutRouterDelegate();

  LogoutRouteConfiguration? _currentConfiguration;
  @override
  LogoutRouteConfiguration? get currentConfiguration => _currentConfiguration;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => const LogoutPage()),
    );
  }

  @override
  Future<void> setNewRoutePath(LogoutRouteConfiguration configuration) {
    _currentConfiguration = configuration;
    notifyListeners();
    return SynchronousFuture(null);
  }
}
