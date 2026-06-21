import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/ui/app/routing/explorer_history_controller.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/ui/explorer/scaffold/account_state_page.dart';
import 'package:phylum/ui/explorer/scaffold/explorer_actions.dart';
import 'package:phylum/ui/explorer/scaffold/explorer_layout_expanded.dart';
import 'package:phylum/ui/common/breakpoints.dart';
import 'package:phylum/ui/explorer/scaffold/search/search.dart';
import 'package:phylum/ui/explorer/scaffold/sync/sync_status_notifier.dart';
import 'package:phylum/ui/explorer/util/clipboard.dart';
import 'package:provider/provider.dart';

import 'explorer_layout_collapsed.dart';

class ExplorerPage extends StatefulWidget {
  final PhylumAccount account;
  final ExplorerLocation location;

  ExplorerPage({required this.account, required this.location})
    : super(key: ValueKey(account.id));

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  late final ExplorerHistoryController _historyController;
  @override
  void initState() {
    super.initState();
    _historyController = ExplorerHistoryController(
      initialLocation: widget.location,
      routerDelegate: context.read(),
    );
  }

  @override
  void didUpdateWidget(ExplorerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _historyController.update(widget.location);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StateNotifierProvider<PhylumAccount, AccountState>.value(
          value: widget.account,
        ),
        StateNotifierProvider<PhylumActionQueue, PhylumActionQueueState>.value(
          value: widget.account.actionQueue,
        ),
        ChangeNotifierProvider(
          create: (context) => SyncStatusNotifier(widget.account.actionQueue),
        ),
        StateNotifierProvider<ExplorerHistoryController, ExplorerHistory>.value(
          value: _historyController,
        ),
        StateNotifierProvider<ExplorerController, ExplorerState>(
          create: (context) => ExplorerController(
            account: context.read(),
            historyController: context.read(),
          ),
          lazy: false,
        ),
        Provider(create: (context) => CutToClipboard()),
        ChangeNotifierProvider(
          create: (context) => SearchFieldController(context),
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
          child: AccountStatePage(child: buildPage(context)),
        );
      },
    );
  }

  Widget buildPage(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final layout = width < maxViewportWidthSmall
        ? const ExplorerLayoutCollapsed()
        : const ExplorerLayoutExpanded();
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
        return ExplorerActions(child: child);
      },
    );
  }
}
