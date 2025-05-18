import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uri/uri.dart';

class AccountSelectorApp extends StatefulWidget {
  final Widget child;
  const AccountSelectorApp({super.key, required this.child});

  @override
  State<AccountSelectorApp> createState() => _AccountSelectorAppState();
}

class _AccountSelectorAppState extends State<AccountSelectorApp> {
  late final delegate = AccountSelectorRouterDelegate(child: widget.child);

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
      title: 'Phylum',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      routeInformationParser: const LoginRouteInformationParser(),
      routerDelegate: delegate,
    );
  }
}

class AccountSelectorRouteConfiguration {
  final String? next;

  AccountSelectorRouteConfiguration(this.next);
}

class LoginRouteInformationParser extends RouteInformationParser<AccountSelectorRouteConfiguration> {
  const LoginRouteInformationParser();

  @override
  Future<AccountSelectorRouteConfiguration> parseRouteInformation(RouteInformation routeInformation) {
    final uri = routeInformation.uri;
    final segments = uri.pathSegments;

    final next = (segments.isEmpty || (segments.length == 1 && (segments[0] == 'home' || segments[0] == 'login')))
        ? null
        : uri.path;
    return SynchronousFuture(AccountSelectorRouteConfiguration(next));
  }

  @override
  RouteInformation? restoreRouteInformation(AccountSelectorRouteConfiguration configuration) {
    final b = UriBuilder()..path = '/login';
    if (configuration.next != null) {
      b.queryParameters['next'] = configuration.next!;
    }

    return RouteInformation(uri: b.build());
  }
}

class AccountSelectorRouterDelegate extends RouterDelegate<AccountSelectorRouteConfiguration>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AccountSelectorRouteConfiguration> {
  final Widget child;
  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  AccountSelectorRouterDelegate({required this.child});

  AccountSelectorRouteConfiguration? _currentConfiguration;
  @override
  AccountSelectorRouteConfiguration? get currentConfiguration => _currentConfiguration;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => child),
    );
  }

  @override
  Future<void> setNewRoutePath(AccountSelectorRouteConfiguration configuration) {
    _currentConfiguration = configuration;
    notifyListeners();
    return SynchronousFuture(null);
  }
}
