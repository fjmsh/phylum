import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show TableOrViewStatements, OrderingTerm;
import 'package:flutter/material.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/actions/action_resource_version_delete.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/file_viewer/file_viewer_dialog.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/time.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';

class ResourceVersionsView extends StatelessWidget {
  final String resourceId;

  ResourceVersionsView({required this.resourceId})
    : super(key: ValueKey(resourceId));

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();

    return Stack(
      children: [
        SingleChildScrollView(
          child: ListTileTheme(
            data: ListTileThemeData(
              visualDensity: VisualDensity.adaptivePlatformDensity,
              titleTextStyle: Theme.of(context).textTheme.labelLarge,
              subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
            ),
            child: StreamBuilder<List<ResourceVersion>>(
              stream:
                  (account.db.resourceVersions.select()
                        ..where((v) => v.resourceId.equals(resourceId))
                        ..orderBy([(o) => OrderingTerm.desc(o.created)]))
                      .watch(),
              initialData: const [],
              builder: (context, snapshot) {
                final versions = snapshot.data ?? const [];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...versions.mapIndexed((i, v) {
                      final sha = v.sha256.isEmpty
                          ? 'Unknown'
                          : v.sha256.substring(0, 12);
                      return ListTile(
                        title: i == 0
                            ? Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: sha),
                                    TextSpan(
                                      text: ' \u2022 Current',
                                      style: TextStyle(fontStyle: .italic),
                                    ),
                                  ],
                                ),
                              )
                            : Text(sha),
                        subtitle: Text(
                          '${v.created.formatLong()} \u2022 ${v.size.formatForDisplay()}',
                        ),
                        trailing: v.deleted
                            ? Text(
                                'Deleted',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              )
                            : PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    onTap: () async {
                                      final r = await account.db.getResource(
                                        resourceId,
                                      );
                                      if (r == null || !context.mounted) return;
                                      downloadResource(context, r, version: v);
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.download),
                                      title: Text('Download'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    enabled: i != 0,
                                    onTap: () async {
                                      final r = await account.db.getResource(
                                        resourceId,
                                      );
                                      if (r == null || !context.mounted) return;
                                      account.addAction(
                                        ResourceVersionDeleteAction(
                                          r: r,
                                          versionId: v.id,
                                        ),
                                      );
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.delete_forever),
                                      title: Text('Delete'),
                                    ),
                                  ),
                                ],
                              ),
                        onTap: () async {
                          final resource = await account.db.getResource(
                            resourceId,
                          );
                          if (resource == null || !context.mounted) return;
                          FilePreviewDialog.showVersions(
                            context,
                            resource,
                            versions,
                            i,
                          );
                        },
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FloatingActionButton(
              onPressed: () async {
                final resource = await account.db.getResource(resourceId);
                if (!context.mounted || resource == null) return;
                pickAndUploadVersion(context, resource);
                // uploadFiles(context, folderId, files)
              },
              tooltip: 'Upload New Version',
              child: Icon(Icons.upload),
            ),
          ),
        ),
      ],
    );
  }
}
