part of 'router.dart';

final _staticPaths = <String, PhylumRoute Function(RouteInformation)>{
  '/': (info) => HomeRoute(instanceUrl: info.uri.queryParameters['instance']),
  '/login': (info) =>
      LoginRoute(instanceUrl: info.uri.queryParameters['instance']),
  '/login/token': (info) => LoginRoute(
    instanceUrl: info.uri.queryParameters['instance'],
    loginMethod: TokenLoginMethod(
      token: info.uri.queryParameters['token'],
      error: info.uri.queryParameters['error'],
    ),
  ),
  '/login/reset_password': (info) => LoginRoute(
    instanceUrl: info.uri.queryParameters['instance'],
    loginMethod: ResetPasswordMethod(
      email: info.uri.queryParameters['email'],
      token: info.uri.queryParameters['token'],
    ),
  ),
  '/setup': (info) =>
      LoginRoute(instanceUrl: info.uri.queryParameters['instance']),
  // '/setup': (info) => info.uri.queryParameters.containsKey('instance')
  //     ? SetupRoute(
  //         instanceUrl: info.uri.queryParameters['instance']!,
  //         config: SetupConfig.fromMap(info.state as Map<String, dynamic>),
  //       )
  //     : const HomeRoute(),
  '/home': (_) => const ExplorerRoute(location: ExplorerLocationHome()),
  '/recents': (_) => const ExplorerRoute(location: ExplorerLocationRecents()),
  '/shared': (_) => const ExplorerRoute(location: ExplorerLocationShared()),
  '/trash': (_) => const ExplorerRoute(location: ExplorerLocationTrash()),
  '/search': (info) => ExplorerRoute(
    location: ExplorerLocationSearch(
      query: info.uri.queryParameters['q'] ?? '',
    ),
  ),
};

class PhylumRouteInformationParser
    extends RouteInformationParser<PhylumRouteConfig> {
  const PhylumRouteInformationParser();

  @override
  Future<PhylumRouteConfig> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    final route = parseUri(routeInformation);
    final uri = routeInformation.uri;
    final nextUri = uri.queryParameters.containsKey('next')
        ? Uri.tryParse(uri.queryParameters['next']!)
        : null;
    final nextRoute = nextUri == null
        ? null
        : parseUri(RouteInformation(uri: nextUri));
    return SynchronousFuture(
      PhylumRouteConfig._(route: route, next: nextRoute),
    );
  }

  PhylumRoute parseUri(RouteInformation info) {
    final uri = info.uri;
    if (_staticPaths.containsKey(uri.path)) {
      return _staticPaths[uri.path]!.call(info);
    }

    final segments = uri.pathSegments;
    if (segments[0] == 'file' && segments.length == 2) {
      return FilePreviewRoute(fileId: segments[1]);
    } else if (segments[0] == 'folder' && segments.length == 2) {
      return ExplorerRoute(
        location: ExplorerLocationFolder(folderId: segments[1]),
      );
    } else if (segments[0] == 'settings') {
      return SettingsRoute(
        selected: Settings.parseSlug(segments.length >= 2 ? segments[1] : ''),
      );
    }

    return UnknownRoute(uri: uri);
  }

  @override
  RouteInformation? restoreRouteInformation(PhylumRouteConfig configuration) {
    return RouteInformation(uri: configuration.uri, state: configuration.state);
  }

  ExplorerLocation? parseExplorerLocation(Uri uri) {
    final segments = uri.pathSegments;

    if (segments.length == 2) {
      if (segments[0] == 'folder') {
        return ExplorerLocationFolder(folderId: segments[1]);
      }
    }
    return null;
  }
}
