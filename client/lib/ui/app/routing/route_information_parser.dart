part of 'router.dart';

final _staticPaths = <String, PhylumRoute Function(Uri)>{
  '/': (uri) => const HomeRoute(),
  '/login': (uri) => const LoginRoute(),
  '/login/token': (uri) => LoginRoute(
    instanceUrl: uri.queryParameters['instance'],
    loginMethod: TokenLoginMethod(uri.queryParameters['token']),
  ),
  '/login/reset_password': (uri) => LoginRoute(
    instanceUrl: uri.queryParameters['instance'],
    loginMethod: ResetPasswordMethod(
      email: uri.queryParameters['email'],
      token: uri.queryParameters['token'],
    ),
  ),
  '/setup': (uri) => uri.queryParameters.containsKey('instance')
      ? SetupRoute(instanceUrl: uri.queryParameters['instance']!)
      : const HomeRoute(),
  '/home': (uri) => const ExplorerRoute(location: ExplorerLocationHome()),
  '/recents': (uri) => const ExplorerRoute(location: ExplorerLocationRecents()),
  '/shared': (uri) => const ExplorerRoute(location: ExplorerLocationShared()),
  '/trash': (uri) => const ExplorerRoute(location: ExplorerLocationTrash()),
  '/search': (uri) => ExplorerRoute(
    location: ExplorerLocationSearch(query: uri.queryParameters['q'] ?? ''),
  ),
};

class PhylumRouteInformationParser
    extends RouteInformationParser<PhylumRouteConfig> {
  const PhylumRouteInformationParser();

  @override
  Future<PhylumRouteConfig> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    final uri = routeInformation.uri;
    final route = parseUri(uri);
    final nextUri = uri.queryParameters.containsKey('next')
        ? Uri.tryParse(uri.queryParameters['next']!)
        : null;
    final nextRoute = nextUri == null ? null : parseUri(nextUri);
    return SynchronousFuture(
      PhylumRouteConfig._(route: route, next: nextRoute),
    );
  }

  PhylumRoute parseUri(Uri uri) {
    if (_staticPaths.containsKey(uri.path)) {
      return _staticPaths[uri.path]!.call(uri);
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
    return RouteInformation(uri: configuration.uri);
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
