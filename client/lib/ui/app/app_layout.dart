import 'package:flutter/material.dart';
import 'package:phylum/ui/app/app_actions.dart';
import 'package:phylum/ui/app/fab_action.dart';
import 'package:phylum/ui/app/nav_list.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/path_view.dart';
import 'package:provider/provider.dart';

enum LayoutType {
  collapsed,
  expandedSmall,
  expandedLarge;

  bool get isExpanded => this == LayoutType.expandedSmall || this == LayoutType.expandedLarge;
}

class LayoutData extends ChangeNotifier {
  LayoutType _type = LayoutType.collapsed;
  LayoutType get type => _type;
  bool _touchUi = true;
  bool get touchUi => _touchUi;

  LayoutData();

  void _update(TargetPlatform platform, Size size) {
    final layout = size.width < 600
        ? LayoutType.collapsed
        : size.width <= 1200
            ? LayoutType.expandedSmall
            : LayoutType.expandedLarge;
    final touchUi = platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    bool changed = false;
    if (_type != layout) {
      _type = layout;
      changed = true;
    }
    if (_touchUi != touchUi) {
      _touchUi = touchUi;
      changed = true;
    }

    if (changed) {
      Future.delayed(const Duration(), notifyListeners);
    }
  }

  @override
  bool operator ==(Object other) {
    return other is LayoutData && other._type == _type && other._touchUi == _touchUi;
  }

  @override
  int get hashCode => _type.hashCode ^ _touchUi.hashCode;
}

class AppLayout extends StatelessWidget {
  final String folderId;

  const AppLayout({super.key, required this.folderId});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final layout = context.watch<LayoutData>();
      return layout.type.isExpanded ? ExpandedAppLayout(folderId: folderId) : CollapsedAppLayout(folderId: folderId);
    });
  }

  static Widget create(String folderId) {
    return ChangeNotifierProvider<LayoutData>(
      create: (context) {
        return LayoutData();
      },
      builder: (context, child) {
        final platform = Theme.of(context).platform;
        final size = MediaQuery.sizeOf(context);
        context.read<LayoutData>()._update(platform, size);
        return child!;
      },
      child: AppActions(
          folderId: folderId,
          child: AppLayout(
            folderId: folderId,
          )),
    );
  }
}

class CollapsedAppLayout extends StatelessWidget {
  final String folderId;

  const CollapsedAppLayout({super.key, required this.folderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phylum')),
      drawer: const Drawer(child: NavList(showFab: false)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showCreateBottomSheet(context);
        },
        child: Icon(Icons.add),
      ),
      body: ExplorerView.create(folderId, ExplorerLayout.noSidebar),
    );
  }

  void showCreateBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return ListView(
            shrinkWrap: true,
            children: [
              for (final action in FabAction.values)
                ListTile(
                  onTap: () {
                    Navigator.of(context).pop();
                    Actions.maybeInvoke(context, action.intent);
                  },
                  title: Text(action.descripiton),
                  leading: action.icon,
                ),
            ],
          );
        });
  }
}

class ExpandedAppLayout extends StatelessWidget {
  final String folderId;

  const ExpandedAppLayout({super.key, required this.folderId});

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<LayoutData>();
    return AppActions(
      folderId: folderId,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              SizedBox(width: 300, child: Text('Phylum')),
              Expanded(child: PathView.create(folderId)),
            ],
          ),
        ),
        body: Row(
          children: [
            SizedBox(
              width: layout.type == LayoutType.expandedLarge ? 300 : 240,
              child: NavList(showFab: true),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: ExplorerView.create(
                    folderId, layout.type == LayoutType.expandedLarge ? ExplorerLayout.largeSidebar : ExplorerLayout.smallSidebar),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
