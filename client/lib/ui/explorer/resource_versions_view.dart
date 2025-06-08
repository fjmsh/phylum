import 'package:drift/drift.dart' show TableOrViewStatements, OrderingTerm;
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';

class ResourceVersionsView extends StatelessWidget {
  final String resourceId;

  ResourceVersionsView({required this.resourceId}) : super(key: ValueKey(resourceId));

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();

    return ListTileTheme(
      data: ListTileThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        titleTextStyle: Theme.of(context).textTheme.labelLarge,
        subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
      ),
      child: StreamBuilder<List<ResourceVersion>>(
          stream: (account.db.resourceVersions.select()
                ..where((v) => v.resourceId.equals(resourceId))
                ..orderBy([(o) => OrderingTerm.desc(o.created)]))
              .watch(),
          initialData: const [],
          builder: (context, snapshot) {
            final versions = snapshot.data ?? const [];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...versions.map((v) => ListTile(
                      title: Text(v.sha256.isEmpty ? 'Unknown' : v.sha256.substring(0, 12)),
                      subtitle: Text('${v.created.formatShort()} \u2022 ${v.size.formatForDisplay()}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: Icon(Icons.remove_red_eye), onPressed: () {}),
                          IconButton(icon: Icon(Icons.download), onPressed: () {}),
                        ],
                      ),
                    )),
              ],
            );
          }),
    );
  }
}
