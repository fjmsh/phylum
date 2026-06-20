import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/account_selector.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/common/dialog_scaffold.dart';
import 'package:phylum/ui/layout/explorer_page.dart';
import 'package:phylum/ui/login/login_page.dart';
import 'package:uri/uri.dart';

sealed class PhylumRouteConfig {
  Uri get uri;

  const PhylumRouteConfig();
}

class HomeRouteConfig extends PhylumRouteConfig {
  @override
  Uri get uri => Uri.parse('/');

  const HomeRouteConfig();
}

abstract class LoggedOutRouteConfig extends PhylumRouteConfig {
  @override
  @nonVirtual
  Uri get uri {
    if (next == const HomeRouteConfig()) {
      return base;
    }

    final builder = UriBuilder.fromUri(base)
      ..queryParameters['next'] = next.uri.toString();
    return builder.build();
  }

  Uri get base;

  final PhylumRouteConfig next;

  const LoggedOutRouteConfig({required this.next});

  List<Page> buildPages();
}

class AccountManagerRouteConfig extends LoggedOutRouteConfig {
  @override
  Uri get base => Uri.parse('/accounts');

  const AccountManagerRouteConfig({required super.next});

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

  LoginRouteConfig({required super.next});

  @override
  List<Page<dynamic>> buildPages() {
    return [MaterialPage(child: LoginPage.create())];
  }
}

// class SetupRoute extends PhylumRouteConfig {
//   final String instanceUrl;

//   SetupRoute({required this.instanceUrl});

//   @override
//   Uri get uri => Uri(path: '/setup');

//   @override
//   Widget buildPage(BuildContext context) {
//     return SetupPage(instanceUrl: instanceUrl);
//   }
// }

// class TokenLoginRoute extends PhylumRouteConfig {
//   final String? instance;
//   final String? token;

//   TokenLoginRoute({this.instance, this.token});

//   @override
//   Uri get uri => Uri(path: '/');

//   @override
//   Widget buildPage(BuildContext context) {
//     return LoginPage.create(
//       instanceUrl: Uri.tryParse(instance ?? ''),
//       method: TokenLoginMethod(token),
//     );
//   }
// }

// class ResetPasswordRoute extends PhylumRouteConfig {
//   final String? instance;
//   final String? email;
//   final String? token;

//   ResetPasswordRoute({
//     required this.instance,
//     required this.email,
//     required this.token,
//   });

//   @override
//   Uri get uri => Uri(path: '/');

//   @override
//   Widget buildPage(BuildContext context) {
//     return LoginPage.create(
//       instanceUrl: Uri.tryParse(instance ?? ''),
//       method: ResetPasswordMethod(email: email, token: token),
//     );
//   }
// }

// sealed class LoggedInRoute extends PhylumRouteConfig {
//   const LoggedInRoute();

//   @nonVirtual
//   @override
//   Widget buildPage(BuildContext context) {
//     final account = context
//         .select<AccountManagerState<PhylumAccount>, PhylumAccount?>(
//           (state) => state.selectedAccount,
//         );

//     if (account == null) {
//       return LoginPage.create();
//     }
//     return buildAccountPage(account);
//   }

//   @protected
//   Widget buildAccountPage(PhylumAccount account);
// }

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
    return [MaterialPage(child: ExplorerPage.create(account, location))];
  }
}
