import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/explorer/explorer_navigator.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/ui/app/action_queue_status_notifier.dart';
import 'package:phylum/ui/app/app_layout.dart';
import 'package:phylum/ui/app/app_logout.dart';
import 'package:phylum/libphylum/explorer/page.dart';
import 'package:provider/provider.dart';

class PhylumApp extends StatefulWidget {
  const PhylumApp({super.key});

  static Widget create(PhylumAccount account) => MultiProvider(
        key: ValueKey(account.id),
        providers: [
          StateNotifierProvider<PhylumAccount, AccountState>.value(value: account),
          StateNotifierProvider<PhylumActionQueue, PhylumActionQueueState>.value(value: account.actionQueue),
          StateNotifierProvider<DownloadManager, DownloadManagerState>(create: (context) => DownloadManager(account)),
          ChangeNotifierProvider(create: (context) => ActionQueueStatusNotifier(account.actionQueue)),
          ChangeNotifierProvider(create: (context) => ExplorerNavigator(account: context.read<PhylumAccount>())),
        ],
        child: PhylumApp(),
      );

  @override
  State<PhylumApp> createState() => _PhylumAppState();
}

class _PhylumAppState extends State<PhylumApp> {
  late final AppLifecycleListener _listener;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onStateChange: (state) {
      if (state == AppLifecycleState.resumed) {
        final account = context.read<PhylumAccount>();
        account.userRepository.refresh();
        account.bookmarkRepository.refresh();
      }
    });
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = context.select<AccountState, bool>((state) => state == AccountState.ready);
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
    if (ready) {
      return MaterialApp.router(
        key: ValueKey('ready'),
        title: 'Phylum',
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        routeInformationParser: const PhylumRouteInformationParser(),
        routerDelegate: PhylumRouterDelegate(navigator: context.watch(), navigatorKey: _navigatorKey),
        shortcuts: getAppShortcuts(),
      );
    }
    return MaterialApp.router(
      key: ValueKey('loggingout'),
      title: 'Logging Out | Phylum',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      routerConfig: createLogoutRouter(),
    );
  }

  RouterConfig<Object> createLogoutRouter() => GoRouter(
        errorBuilder: (context, state) => const AppLogout(),
        routes: [],
      );
}

class PhylumRouteInformationParser extends RouteInformationParser<ExplorerPage> {
  const PhylumRouteInformationParser();

  @override
  Future<ExplorerPage> parseRouteInformation(RouteInformation routeInformation) {
    final uri = routeInformation.uri;
    final segments = uri.pathSegments;

    if (segments.isEmpty) {
      return SynchronousFuture(const ExplorerPageHome());
    }
    if (segments.length == 1) {
      if (segments[0] == 'home') {
        return SynchronousFuture(const ExplorerPageHome());
      }
      if (segments[0] == 'recents') {
        return SynchronousFuture(const ExplorerPageRecents());
      }
      if (segments[0] == 'shared') {
        return SynchronousFuture(const ExplorerPageShared());
      }
      if (segments[0] == 'trash') {
        return SynchronousFuture(const ExplorerPageTrash());
      }
    } else if (segments.length == 2 && segments[0] == 'folder') {
      return SynchronousFuture(ExplorerPageFolder(folderId: segments[1]));
    }
    return SynchronousFuture(ExplorerPageFolder(folderId: 'unknown'));
  }

  @override
  RouteInformation? restoreRouteInformation(ExplorerPage configuration) {
    return RouteInformation(uri: configuration.uri);
  }
}

class PhylumRouterDelegate extends RouterDelegate<ExplorerPage>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<ExplorerPage> {
  final ExplorerNavigator navigator;
  final GlobalKey<NavigatorState> navigatorKey;

  PhylumRouterDelegate({required this.navigator, required this.navigatorKey});

  @override
  ExplorerPage? get currentConfiguration => navigator.current;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => const AppLayout()),
      // pages: [
      //   MaterialPage(
      //     child: const AppLayout(),
      //     onPopInvoked: (didPop, result) => navigator.goBack(),
      //   )
      // ],
    );
  }

  @override
  Future<void> setInitialRoutePath(ExplorerPage configuration) {
    navigator.go(configuration);
    return SynchronousFuture(null);
  }

  @override
  Future<void> setNewRoutePath(ExplorerPage configuration) {
    // navigator.go(configuration);
    return SynchronousFuture(null);
  }
}

// sealed class PhylumRoute {
//   Uri get uri;

//   ExplorerPage get page;

//   const PhylumRoute();
// }

// class PhylumRouteHome extends PhylumRoute {
//   @override
//   Uri get uri => Uri(path: '/home');

//   @override
//   ExplorerPage get page => const ExplorerPageHome();

//   const PhylumRouteHome();
// }

// class PhylumRouteFolder extends PhylumRoute {
//   @override
//   Uri get uri => Uri(path: '/folder/$folderId');

//   final String folderId;

//   @override
//   ExplorerPage get page => ExplorerPageFolder(folderId: folderId);

//   const PhylumRouteFolder(this.folderId);
// }

// class PhylumRouteRecents extends PhylumRoute {
//   @override
//   Uri get uri => Uri(path: '/recents');

//   @override
//   ExplorerPage get page => const ExplorerPageRecents();

//   const PhylumRouteRecents();
// }

// class PhylumRouteShared extends PhylumRoute {
//   @override
//   Uri get uri => Uri(path: '/shared');

//   @override
//   ExplorerPage get page => const ExplorerPageShared();

//   const PhylumRouteShared();
// }

// class PhylumRouteTrash extends PhylumRoute {
//   @override
//   Uri get uri => Uri(path: '/trash');

//   @override
//   ExplorerPage get page => const ExplorerPageTrash();

//   const PhylumRouteTrash();
// }
