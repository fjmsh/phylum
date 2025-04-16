import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/ui/app/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:provider/provider.dart';

const reverse = false;
const small = false;

class PathView extends StatefulWidget {
  const PathView._() : super();

  static Widget create() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: small
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: PathView._(),
      ),
    );
  }

  @override
  State<PathView> createState() => _PathViewState();
}

class _PathViewState extends State<PathView> {
  StreamSubscription? sub;
  late final PhylumRouterDelegate _navigator;
  Iterable<ParentsResult>? ancestors;

  @override
  void initState() {
    super.initState();
    _navigator = context.read<PhylumRouterDelegate>();
    _navigator.addListener(onNavigatorUpdated);
    onNavigatorUpdated();
  }

  void onNavigatorUpdated() {
    sub?.cancel();
    sub = _navigator.current?.watchParents(context.read<PhylumAccount>()).listen((data) {
      SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription(
        label: data.isEmpty ? 'Phylum' : "${data.first.name == "" ? "/" : data.first.name} | Phylum",
      ));
      if (mounted) {
        setState(() {
          ancestors = reverse ? data : data.reversed;
        });
      }
    });
  }

  @override
  void dispose() {
    _navigator.removeListener(onNavigatorUpdated);
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
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in ancestors)
          ResourceDragTarget(
            resourceId: r.id,
            buildItem: (context, dropTargetActive) => Card(
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                side: dropTargetActive ? BorderSide(width: 2, color: theme.colorScheme.primary) : BorderSide.none,
              ),
              elevation: r == current ? 0 : null,
              margin: EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                onTap: r == current ? null : () => Actions.maybeInvoke(context, NavToFolderIntent(folderId: r.id)),
                child: Padding(
                  padding: small
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                      : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(r.name,
                      style: small
                          ? theme.textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: r == current ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)
                          : theme.textTheme.bodyLarge!.copyWith(
                              color: r == current ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
