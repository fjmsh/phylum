import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/libphylum/explorer/explorer_navigator.dart';
import 'package:provider/provider.dart';

const reverse = false;

class PathView extends StatefulWidget {
  const PathView._() : super();

  static Widget create() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: PathView._(),
      ),
    );
  }

  @override
  State<PathView> createState() => _PathViewState();
}

class _PathViewState extends State<PathView> {
  StreamSubscription? sub;
  Function()? removeListener;
  Iterable<ParentsResult>? ancestors;

  @override
  void initState() {
    super.initState();
    removeListener = context.read<ExplorerNavigator>().addListener((state) {
      sub?.cancel();
      sub = state.current.watchParents(context.read<PhylumAccount>()).listen((data) {
        SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription(
          label: data.isEmpty ? 'Phylum' : "${data.first.name == "" ? "/" : data.first.name} | Phylum",
        ));
        if (mounted) {
          setState(() {
            ancestors = reverse ? data : data.reversed;
          });
        }
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    removeListener?.call();
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ancestors = this.ancestors;
    if (ancestors == null || ancestors.isEmpty) {
      return const SizedBox();
    }
    final current = reverse ? ancestors.firstOrNull : ancestors.lastOrNull;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in ancestors)
          ResourceDragTarget(
            resourceId: r.id,
            buildItem: (context, dropTargetActive) => Card(
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                side: dropTargetActive ? BorderSide(width: 2, color: Theme.of(context).colorScheme.primary) : BorderSide.none,
              ),
              margin: EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                onTap: r == current ? null : () => Actions.maybeInvoke(context, NavToFolderIntent(folderId: r.id)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    r.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
