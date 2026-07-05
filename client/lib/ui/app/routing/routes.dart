part of 'router.dart';

sealed class PhylumRoute {
  Uri get uri;

  bool get dialog => false;

  Object? get state => null;

  const PhylumRoute();

  Widget buildPage(PhylumAccount? account);
}

class HomeRoute extends PhylumRoute {
  @override
  Uri get uri => Uri.parse('/');

  final String? instanceUrl;

  const HomeRoute({this.instanceUrl});

  @override
  Widget buildPage(PhylumAccount? account) => account == null
      ? LoginPage(instanceUri: Uri.tryParse(instanceUrl ?? ''))
      : ExplorerPage(account: account, location: ExplorerLocationHome());
}

class UnknownRoute extends PhylumRoute {
  @override
  final Uri uri;

  UnknownRoute({required this.uri});

  @override
  Widget buildPage(PhylumAccount? account) => account == null
      // TODO: #implement UnknownRoutePage
      ? LoginPage()
      : ExplorerPage(account: account, location: ExplorerLocationHome());
}

abstract class LoggedOutRoute extends PhylumRoute {
  const LoggedOutRoute();
}

class _AccountManagerRoute extends PhylumRoute {
  @override
  Uri get uri => Uri.parse('/accounts');

  const _AccountManagerRoute();

  @override
  Widget buildPage(PhylumAccount? account) {
    return PhylumDialogScaffold(child: const AccountSelector());
  }
}

class LoginRoute extends LoggedOutRoute {
  @override
  Uri get uri => Uri.parse('/login');

  final String? instanceUrl;
  final LoginMethod? loginMethod;

  const LoginRoute({this.instanceUrl, this.loginMethod});

  @override
  Widget buildPage(PhylumAccount? account) {
    return LoginPage(
      instanceUri: Uri.tryParse(instanceUrl ?? ''),
      selectedMethod: loginMethod,
    );
  }
}

class SetupRoute extends LoggedOutRoute {
  @override
  Uri get uri => Uri(path: '/setup');

  @override
  bool get dialog => true;

  @override
  Object? get state => _config.toMap();

  final String instanceUrl;

  final SetupConfig _config;

  SetupRoute({required this.instanceUrl, required this._config});

  @override
  Widget buildPage(PhylumAccount? account) {
    return SetupPage(instanceUrl: instanceUrl, overrides: _config.overrides);
  }
}

abstract class LoggedInRoute extends PhylumRoute {
  const LoggedInRoute();
}

class ExplorerRoute extends LoggedInRoute {
  final ExplorerLocation location;

  const ExplorerRoute({required this.location});

  @override
  Uri get uri => location.uri;

  @override
  Widget buildPage(PhylumAccount? account) {
    return ExplorerPage(account: account!, location: location);
  }
}

class SettingsRoute extends LoggedInRoute {
  final Settings? selected;

  @override
  Uri get uri => selected == null
      ? Uri(path: '/settings')
      : Uri(path: '/settings/${selected!.slug}');

  @override
  bool get dialog => true;

  SettingsRoute({this.selected});

  @override
  Widget buildPage(PhylumAccount? account) {
    return SettingsPage(account: account!, selected: selected);
  }
}

class FilePreviewRoute extends LoggedInRoute {
  final String fileId;

  @override
  Uri get uri => Uri(path: '/file/$fileId');

  @override
  bool get dialog => true;

  const FilePreviewRoute({required this.fileId}) : super();

  @override
  Widget buildPage(PhylumAccount? account) {
    return FilePreviewPage.create(account: account!, resourceId: fileId);
  }
}
