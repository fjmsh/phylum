import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/libphylum/actions/action_resource_publink_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/details/create_publink_view.dart';
import 'package:provider/provider.dart';

class ResourcePublinksView extends StatelessWidget {
  final Resource resource;

  ResourcePublinksView({required this.resource})
    : super(key: ValueKey(resource.id));

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();

    return ListTileTheme(
      data: ListTileThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        titleTextStyle: Theme.of(context).textTheme.labelLarge,
        subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
      ),
      child: StreamBuilder<List<String>>(
        stream: context
            .read<PhylumAccount>()
            .db
            .selectPublinks(resource.id)
            .map((l) => l.id)
            .watch(),
        initialData: const [],
        builder: (context, snapshot) {
          final publinks = snapshot.data ?? const [];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...publinks.map(
                (l) => ListTile(
                  title: Text(l),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      final publinkPath = context
                          .read<PhylumAccount>()
                          .config
                          .publinkPath;
                      Clipboard.setData(
                        ClipboardData(
                          text: account.apiClient
                              .createUri('$publinkPath/$l')
                              .toString(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add'),
                onPressed: () async {
                  final account = context.read<PhylumAccount>();
                  final info = await CreatePublinkView.show(
                    context,
                    resource.id,
                  );
                  if (info == null) return;
                  account.addAction(
                    ResourcePublinkCreateAction(
                      resourceId: resource.id,
                      publinkId: info.id,
                      password: info.password,
                      expires: info.expiration,
                      accessLimit: info.accessLimit,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
