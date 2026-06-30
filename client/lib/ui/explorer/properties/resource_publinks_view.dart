import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/libphylum/actions/action_resource_publink_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/properties/create_publink_view.dart';
import 'package:phylum/util/permissions.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';

class ResourcePublinksView extends StatefulWidget {
  final Resource resource;

  ResourcePublinksView({required this.resource})
    : super(key: ValueKey(resource.id));

  @override
  State<ResourcePublinksView> createState() => _ResourcePublinksViewState();
}

class _ResourcePublinksViewState extends State<ResourcePublinksView> {
  final expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    final bool hasSharePermission =
        (widget.resource.userPermission | account.user.filesPermissions) &
            permissionShare !=
        0;

    return ListTileTheme(
      data: ListTileThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        titleTextStyle: Theme.of(context).textTheme.labelLarge,
        subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
      ),
      child: StreamBuilder<List<Publink>>(
        stream: context
            .read<PhylumAccount>()
            .db
            .selectPublinks(widget.resource.id)
            .watch(),
        initialData: const [],
        builder: (context, snapshot) {
          final publinks = snapshot.data ?? const [];
          return Stack(
            children: [
              publinks.isEmpty
                  ? Center(child: Text('No public shares'))
                  : SingleChildScrollView(
                      child: Column(
                        spacing: 18,
                        children: [
                          ExpansionPanelList(
                            expansionCallback: (i, expanded) => setState(
                              () => expanded
                                  ? this.expanded.add(publinks[i].id)
                                  : this.expanded.remove(publinks[i].id),
                            ),
                            children: publinks
                                .map((l) {
                                  return buildPanel(
                                    l,
                                    account,
                                    hasSharePermission,
                                  );
                                })
                                .toList(growable: false),
                          ),
                        ],
                      ),
                    ),
              if (hasSharePermission)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FloatingActionButton(
                      onPressed: () async {
                        final account = context.read<PhylumAccount>();
                        final info = await CreatePublinkView.show(
                          context,
                          widget.resource.id,
                        );
                        if (info == null) return;
                        account.addAction(
                          ResourcePublinkCreateAction(
                            resourceId: widget.resource.id,
                            publinkId: info.id,
                            password: info.password,
                            expires: info.expiration,
                            accessLimit: info.accessLimit,
                          ),
                        );
                      },
                      tooltip: 'Create New Link',
                      child: Icon(Icons.link),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  ExpansionPanel buildPanel(
    Publink l,
    PhylumAccount account,
    bool hasSharePermission,
  ) {
    return ExpansionPanel(
      isExpanded: expanded.contains(l.id),
      canTapOnHeader: true,
      headerBuilder: (context, expanded) => ListTile(title: Text(l.id)),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Accessed ',
                    style: TextStyle(fontWeight: .bold),
                  ),

                  TextSpan(text: l.accessed.toString()),
                  if (l.accessLimit > 0) TextSpan(text: ' of ${l.accessLimit}'),
                  TextSpan(text: ' times'),
                ],
              ),
            ),
            if (l.expires != null)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Expires ',
                      style: TextStyle(fontWeight: .bold),
                    ),
                    TextSpan(text: l.expires!.formatLong()),
                  ],
                ),
              ),
            if (l.protected)
              Text('Password Protected', style: TextStyle(fontWeight: .bold)),
            Row(
              mainAxisAlignment: .end,
              children: [
                if (hasSharePermission)
                  TextButton.icon(
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: Theme.of(
                      //   context,
                      // ).colorScheme.onError,
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    label: Text('Delete'),
                    icon: const Icon(Icons.delete),
                    onPressed: () {},
                  ),
                if (hasSharePermission)
                  TextButton.icon(
                    label: Text('Edit'),
                    icon: const Icon(Icons.edit),
                    onPressed: () {},
                  ),
                TextButton.icon(
                  label: Text('Copy URL'),
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    final publinkPath = context
                        .read<PhylumAccount>()
                        .config
                        .publinkPath;
                    Clipboard.setData(
                      ClipboardData(
                        text: account.apiClient
                            .createUri('$publinkPath/${l.id}')
                            .toString(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
