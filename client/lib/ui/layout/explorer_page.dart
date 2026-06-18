import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/ui/app/routing/explorer_history_controller.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/ui/layout/account_state_page.dart';
import 'package:phylum/ui/layout/app_actions.dart';
import 'package:phylum/ui/layout/explorer_page_expanded.dart';
import 'package:phylum/ui/layout/responsive.dart';
import 'package:phylum/ui/layout/search.dart';
import 'package:phylum/ui/layout/sync_status_notifier.dart';
import 'package:provider/provider.dart';

import 'explorer_page_collapsed.dart';

class ExplorerPage extends StatelessWidget {
  const ExplorerPage._();

  static Widget create(PhylumAccount account, ExplorerLocation location) {
    return MultiProvider(
      key: ValueKey(account.id),
      providers: [
        StateNotifierProvider<PhylumAccount, AccountState>.value(
          value: account,
        ),
        StateNotifierProvider<PhylumActionQueue, PhylumActionQueueState>.value(
          value: account.actionQueue,
        ),
        ChangeNotifierProvider(
          create: (context) => SyncStatusNotifier(account.actionQueue),
        ),
        StateNotifierProvider<ExplorerHistoryController, ExplorerHistory>(
          create: (context) =>
              ExplorerHistoryController(initialLocation: location),
          lazy: false,
        ),
        StateNotifierProvider<ExplorerController, ExplorerState>(
          create: (context) => ExplorerController(
            account: context.read(),
            historyController: context.read(),
          ),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (context) => PhylumSearchController(context),
        ),
      ],
      builder: (context, child) {
        final canHandlePop =
            context.watch<ExplorerHistoryController>().canGoBack ||
            context.watch<ExplorerState>().selectedIds.isNotEmpty;
        return PopScope(
          canPop: !canHandlePop,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (!context.read<ExplorerController>().clearSelection()) {
              context.read<ExplorerHistoryController>().goBack();
            }
          },
          child: AccountStatePage(child: const ExplorerPage._()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final layout = width < maxViewportWidthSmall
        ? const ExplorerPageCollapsed()
        : const ExplorerPageExpanded();
    return ExternalDropRegion(
      buildItem: (context, dropTargetActive) {
        final child = (dropTargetActive)
            ? Stack(
                children: [
                  layout,
                  ConstrainedBox(
                    constraints: BoxConstraints.expand(),
                    child: Material(
                      color: Colors.white70,
                      child: const Center(
                        child: Text(
                          'Drop Files to Upload',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : layout;
        return AppActions(child: child);
      },
    );
  }
}
