import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/account_selector.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/common/dialog_scaffold.dart';
import 'package:phylum/ui/explorer/scaffold/explorer_page.dart';
import 'package:phylum/ui/login/login_controller.dart';
import 'package:phylum/ui/login/login_page.dart';
import 'package:phylum/ui/settings/settings.dart';
import 'package:phylum/ui/settings/settings_page.dart';
import 'package:phylum/ui/setup/setup_page.dart';

part 'route_config.dart';
part 'route_information_parser.dart';
part 'routes.dart';

class PhylumRouterDelegate extends RouterDelegate<PhylumRouteConfig>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();
  @override
  PhylumRouteConfig get currentConfiguration => _current;
  PhylumRouteConfig _current = PhylumRouteConfig._empty();

  late AccountManagerState<PhylumAccount> _accountManagerState;
  List<Page> pages = const [];

  PhylumRouterDelegate({
    required AccountManager<PhylumAccount> accountManager,
  }) {
    accountManager.addListener(onAccountManagerUpdated);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: pages,
      onDidRemovePage: (page) {
        if (_current.route.stackable) {
          go(_current.base ?? const HomeRoute());
        }
        // if (_current.stack.length > 1) {
        //   _current = PhylumRouteConfig._(
        //     stack: List.of(_current.stack)..removeLast(),
        //   );
        //   _rebuildPages();
        // }
      },
      // onGenerateRoute: (settings) =>
      //     MaterialPageRoute(builder: (context) => const AccountSelector()),
    );
  }

  @override
  Future<void> setNewRoutePath(PhylumRouteConfig configuration) {
    go(configuration.route, next: configuration.next);
    return SynchronousFuture(null);
  }

  void go(PhylumRoute route, {PhylumRoute? next}) {
    if (_current.route != route) {
      _current = PhylumRouteConfig._(
        route: route,
        next: next ?? _current.next,
        base: route.stackable
            ? _current.route.stackable
                  ? _current.base
                  : _current.route
            : null,
      );
      normalizeConfig();
    }
  }

  void onAccountManagerUpdated(AccountManagerState<PhylumAccount> state) {
    _accountManagerState = state;
    normalizeConfig();
  }

  void normalizeConfig() {
    var config = currentConfiguration;
    if (_accountManagerState.status != AccountManagerStatus.ready ||
        _accountManagerState.invalidAccounts.isNotEmpty) {
      config = PhylumRouteConfig._(
        route: const _AccountManagerRoute(),
        next: config.route,
      );
    } else {
      if (config.next != null) {
        config = PhylumRouteConfig._(route: config.next!);
      }
      final account = _accountManagerState.selectedAccount;
      if (account == null) {
        if (config.route is LoggedInRoute) {
          config = PhylumRouteConfig._(
            route: const LoginRoute(),
            next: config.route,
          );
        }
      } else if (config.route is LoggedOutRoute) {
        config = PhylumRouteConfig._(route: const HomeRoute());
      }
    }

    _current = config;
    _rebuildPages();
    notifyListeners();
  }

  void _rebuildPages() {
    final account = _accountManagerState.selectedAccount;
    pages = [
      if (_current.route.stackable)
        MaterialPage(
          child: (_current.base ?? const HomeRoute()).buildPage(account),
        ),
      MaterialPage(child: _current.route.buildPage(account)),
    ];
  }
}
