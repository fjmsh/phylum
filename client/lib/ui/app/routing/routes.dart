import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/layout/explorer_page.dart';
import 'package:phylum/ui/login/login_controller.dart';
import 'package:phylum/ui/login/login_page.dart';
import 'package:phylum/ui/setup/setup_page.dart';
import 'package:phylum/ui/open/open_resource_page.dart';
import 'package:phylum/ui/file_viewer/file_viewer_page.dart';
import 'package:provider/provider.dart';

sealed class PhylumRoute {
  Uri get uri;

  const PhylumRoute();

  Widget buildPage(BuildContext context);
}

class SetupRoute extends PhylumRoute {
  final String instanceUrl;

  SetupRoute({required this.instanceUrl});

  @override
  Uri get uri => Uri(path: '/setup');

  @override
  Widget buildPage(BuildContext context) {
    return SetupPage(instanceUrl: instanceUrl);
  }
}

class TokenLoginRoute extends PhylumRoute {
  final String? instance;
  final String? token;

  TokenLoginRoute({this.instance, this.token});

  @override
  Uri get uri => Uri(path: '/');

  @override
  Widget buildPage(BuildContext context) {
    return LoginPage.create(
      instanceUrl: Uri.tryParse(instance ?? ''),
      method: TokenLoginMethod(token),
    );
  }
}

class ResetPasswordRoute extends PhylumRoute {
  final String? instance;
  final String? email;
  final String? token;

  ResetPasswordRoute({
    required this.instance,
    required this.email,
    required this.token,
  });

  @override
  Uri get uri => Uri(path: '/');

  @override
  Widget buildPage(BuildContext context) {
    return LoginPage.create(
      instanceUrl: Uri.tryParse(instance ?? ''),
      method: ResetPasswordMethod(email: email, token: token),
    );
  }
}

sealed class LoggedInRoute extends PhylumRoute {
  const LoggedInRoute();

  @nonVirtual
  @override
  Widget buildPage(BuildContext context) {
    final account = context
        .select<AccountManagerState<PhylumAccount>, PhylumAccount?>(
          (state) => state.selectedAccount,
        );

    if (account == null) {
      return LoginPage.create();
    }
    return buildAccountPage(account);
  }

  @protected
  Widget buildAccountPage(PhylumAccount account);
}

class OpenResourceRoute extends LoggedInRoute {
  final String resourceId;

  @override
  Uri get uri => Uri(path: '/open', queryParameters: {'id': resourceId});

  OpenResourceRoute({required this.resourceId}) : super();

  @override
  Widget buildAccountPage(PhylumAccount account) {
    return OpenResourcePage(account: account, resourceId: resourceId);
  }
}

class FilePreviewRoute extends LoggedInRoute {
  final String fileId;

  @override
  Uri get uri => Uri(path: '/file/$fileId');

  const FilePreviewRoute({required this.fileId}) : super();

  @override
  Widget buildAccountPage(PhylumAccount account) {
    return FilePreviewPage.create(account: account, resourceId: fileId);
  }
}

class ExplorerRoute extends LoggedInRoute {
  final ExplorerLocation location;

  const ExplorerRoute({required this.location});

  @override
  Uri get uri => location.uri;

  @override
  Widget buildAccountPage(PhylumAccount account) {
    return ExplorerPage.create(account, location);
  }
}
