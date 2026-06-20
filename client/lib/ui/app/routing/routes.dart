part of 'router.dart';

sealed class PhylumRouteConfig {
  Uri get uri;

  const PhylumRouteConfig();
}

class HomeRouteConfig extends PhylumRouteConfig {
  @override
  Uri get uri => Uri.parse('/');

  const HomeRouteConfig();
}

class UnknownRouteConfig extends PhylumRouteConfig {
  @override
  final Uri uri;

  UnknownRouteConfig({required this.uri});
}

abstract class LoggedOutRouteConfig extends PhylumRouteConfig {
  @override
  @nonVirtual
  Uri get uri {
    if (next == const HomeRouteConfig()) {
      return base;
    }

    final builder = UriBuilder.fromUri(base)
      ..queryParameters['next'] = next.uri.path.toString();
    return builder.build();
  }

  Uri get base;

  @protected
  PhylumRouteConfig next = const HomeRouteConfig();

  LoggedOutRouteConfig();

  List<Page> buildPages();
}

class AccountManagerRouteConfig extends LoggedOutRouteConfig {
  @override
  Uri get base => Uri.parse('/accounts');

  AccountManagerRouteConfig();

  @override
  List<Page<dynamic>> buildPages() {
    return [
      MaterialPage(child: PhylumDialogScaffold(child: const AccountSelector())),
    ];
  }
}

class LoginRouteConfig extends LoggedOutRouteConfig {
  @override
  Uri get base => Uri.parse('/login');

  final String? instanceUrl;
  final LoginMethod? loginMethod;

  LoginRouteConfig({this.instanceUrl, this.loginMethod});

  @override
  List<Page<dynamic>> buildPages() {
    return [
      MaterialPage(
        child: LoginPage.create(
          instanceUrl: Uri.tryParse(instanceUrl ?? ''),
          method: loginMethod,
        ),
      ),
    ];
  }
}

class SetupRoute extends LoggedOutRouteConfig {
  final String instanceUrl;

  SetupRoute({required this.instanceUrl});

  @override
  Uri get base => Uri(path: '/setup');

  @override
  List<Page> buildPages() {
    return [MaterialPage(child: SetupPage(instanceUrl: instanceUrl))];
  }
}

// class OpenResourceRoute extends LoggedInRoute {
//   final String resourceId;

//   @override
//   Uri get uri => Uri(path: '/open', queryParameters: {'id': resourceId});

//   OpenResourceRoute({required this.resourceId}) : super();

//   @override
//   Widget buildAccountPage(PhylumAccount account) {
//     return OpenResourcePage(account: account, resourceId: resourceId);
//   }
// }

// class FilePreviewRoute extends LoggedInRoute {
//   final String fileId;

//   @override
//   Uri get uri => Uri(path: '/file/$fileId');

//   const FilePreviewRoute({required this.fileId}) : super();

//   @override
//   Widget buildAccountPage(PhylumAccount account) {
//     return FilePreviewPage.create(account: account, resourceId: fileId);
//   }
// }

abstract class LoggedInRouteConfig extends PhylumRouteConfig {
  const LoggedInRouteConfig();

  List<Page<dynamic>> buildPages(PhylumAccount account);
}

class ExplorerRoute extends LoggedInRouteConfig {
  final ExplorerLocation location;

  const ExplorerRoute({required this.location});

  @override
  Uri get uri => location.uri;

  @override
  List<Page<dynamic>> buildPages(PhylumAccount account) {
    return [
      MaterialPage(
        child: ExplorerPage(account: account, location: location),
      ),
    ];
  }
}
