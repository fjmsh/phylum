import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uri/uri.dart';

import 'login_page.dart';

class LoginApp extends StatefulWidget {
  const LoginApp({super.key});

  @override
  State<LoginApp> createState() => _LoginAppState();
}

class _LoginAppState extends State<LoginApp> {
  final delegate = LoginRouterDelegate();

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
      routeInformationParser: const LoginRouteInformationParser(),
      routerDelegate: delegate,
    );
  }
}

class LoginRouteConfiguration {
  final String? next;

  LoginRouteConfiguration(this.next);
}

class LoginRouteInformationParser extends RouteInformationParser<LoginRouteConfiguration> {
  const LoginRouteInformationParser();

  @override
  Future<LoginRouteConfiguration> parseRouteInformation(RouteInformation routeInformation) {
    final uri = routeInformation.uri;
    final segments = uri.pathSegments;

    final next = (segments.isEmpty || (segments.length == 1 && (segments[0] == 'home' || segments[0] == 'login')))
        ? null
        : uri.path;
    return SynchronousFuture(LoginRouteConfiguration(next));
  }

  @override
  RouteInformation? restoreRouteInformation(LoginRouteConfiguration configuration) {
    final b = UriBuilder()..path = '/login';
    if (configuration.next != null) {
      b.queryParameters['next'] = configuration.next!;
    }

    return RouteInformation(uri: b.build());
  }
}

class LoginRouterDelegate extends RouterDelegate<LoginRouteConfiguration>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<LoginRouteConfiguration> {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  LoginRouterDelegate();

  LoginRouteConfiguration? _currentConfiguration;
  @override
  LoginRouteConfiguration? get currentConfiguration => _currentConfiguration;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Future<void> setNewRoutePath(LoginRouteConfiguration configuration) {
    _currentConfiguration = configuration;
    notifyListeners();
    return SynchronousFuture(null);
  }
}
