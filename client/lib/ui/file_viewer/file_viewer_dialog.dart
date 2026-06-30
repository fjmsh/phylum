import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/shortcuts/intents.dart';
import 'package:phylum/ui/file_viewer/file_viewer_scaffold.dart';
import 'package:phylum/ui/file_viewer/versioned_resource.dart';
import 'package:provider/provider.dart';

import 'file_viewer.dart';

class FilePreviewDialog extends StatefulWidget {
  final List<VersionedResource> resources;
  final int index;

  const FilePreviewDialog({
    super.key,
    required this.resources,
    required this.index,
  });

  static Future<void> showResources(
    BuildContext context,
    List<Resource> resources,
    int index,
  ) async {
    final account = context.read<PhylumAccount>();
    final r = await Future.wait(
      resources.map(
        (r) async => VersionedResource(
          r: r,
          v: await account.db.latestVersion(r.id).getSingle(),
          showTimestamp: true,
        ),
      ),
    );
    if (!context.mounted) return;
    _show(context, r, index);
  }

  static Future<void> showVersions(
    BuildContext context,
    Resource resource,
    Iterable<ResourceVersion> versions,
    int index,
  ) async {
    final r = versions
        .map((v) => VersionedResource(r: resource, v: v, showTimestamp: false))
        .toList(growable: false);
    _show(context, r, index);
  }

  static Future<void> _show(
    BuildContext context,
    List<VersionedResource> resources,
    int index,
  ) async {
    final account = context.read<PhylumAccount>();
    return showDialog(
      context: context,
      builder: (context) => MultiProvider(
        providers: [
          Provider.value(value: account),
          Provider.value(value: account.actionQueue),
        ],
        builder: (context, child) {
          return FilePreviewDialog(resources: resources, index: index);
        },
      ),
    );
  }

  @override
  State<FilePreviewDialog> createState() => _FilePreviewDialogState();
}

class _FilePreviewDialogState extends State<FilePreviewDialog> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.index;
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (i) => Navigator.of(context).pop(),
          ),
          FocusLeftIntent: CallbackAction<FocusLeftIntent>(
            onInvoke: (FocusLeftIntent i) {
              return setState(() {
                if (index <= 0) {
                  index = widget.resources.length;
                }
                index--;
              });
            },
          ),
          FocusRightIntent: CallbackAction<FocusRightIntent>(
            onInvoke: (FocusRightIntent i) {
              return setState(() {
                index++;
                if (index >= widget.resources.length) {
                  index = 0;
                }
              });
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: FileViewerScaffold(
            resource: widget.resources[index],
            body: FileViewer(resource: widget.resources[index]),
          ),
        ),
      ),
    );
  }
}
