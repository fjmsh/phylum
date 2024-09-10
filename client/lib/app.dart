import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app_layout.dart';
import 'package:provider/provider.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      name: 'home',
      path: '/',
      builder: (context, state) => const AppScaffold(),
    ),
  ],
);

class PhylumApp extends StatelessWidget {
  final String accountId;

  PhylumApp({required this.accountId}) : super(key: ValueKey(accountId));

  @override
  Widget build(BuildContext context) {
    final account = context.select<AccountManagerState<PhylumAccount>, PhylumAccount?>((state) => state.accounts[accountId]);
    if (account == null) return Container();
    return MultiProvider(
      providers: [
        Provider.value(value: account),
        StateNotifierProvider<ApiActionQueue, ApiActionQueueState>.value(value: account.actionQueue),
      ],
      child: MaterialApp.router(
        key: ValueKey(account),
        title: 'Phylum',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange)),
        darkTheme: ThemeData.dark(),
        routerConfig: _router,
        shortcuts: getAppShortcuts(),
      ),
    );
  }
}
