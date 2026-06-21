import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/details/resource_info_view.dart';
import 'package:provider/provider.dart';

class ReactiveResourceInfoView extends StatelessWidget {
  const ReactiveResourceInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    final resource = context.select<ExplorerState, Resource?>((state) {
      return state.focussedIfSelected ?? state.folder;
    });

    if (resource == null) {
      return const Center(child: Text(''));
    }
    return Column(
      children: [
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border(bottom: Divider.createBorderSide(context)),
          ),
          child: ListTile(
            title: Text(
              resource.name,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: ResourceInfoView(resource: resource),
          ),
        ),
      ],
    );
  }
}
