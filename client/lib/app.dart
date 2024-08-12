import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/folder_view.dart';
import 'package:phylum/home_page.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => NavScaffold(child: child),
      routes: [
        GoRoute(name: 'home', path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
            name: 'dir',
            path: '/dir/:id',
            builder: (context, state) {
              return FolderView(id: state.pathParameters['id']!);
            }),
      ],
    )
  ],
);

class PhylumApp extends StatelessWidget {
  final String accountId;

  const PhylumApp({super.key, required this.accountId});

  @override
  Widget build(BuildContext context) {
    final account = context.select<AccountManagerState<PhylumAccount>, PhylumAccount?>((state) => state.accounts[accountId]);
    if (account == null) return Container();
    return MultiProvider(
      providers: [
        Provider.value(value: account),
        StateNotifierProvider<ApiActionQueue, ApiActionQueueState>.value(value: account.actionQueue),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatelessWidget {
  const _AppContent();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Phylum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange)),
      darkTheme: ThemeData.dark(),
      routerConfig: _router,
    );
  }
}

class NavScaffold extends StatelessWidget {
  final Widget child;
  const NavScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phylum'),
        leading: router.canPop() ? BackButton(onPressed: router.pop) : null,
      ),
      body: child,
    );
  }
}
