import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

class PathView extends StatelessWidget {
  final String id;

  PathView._({required this.id}) : super(key: ValueKey(id));

  static Widget create(String id) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: PathView._(id: id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    return StreamBuilder(
      stream: account.db.managers.resources.filter((r) => r.id.equals(id)).watchSingleOrNull(),
      builder: (context, snapshot) {
        final r = snapshot.data;
        if (r == null) {
          return const SizedBox();
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (r.parent != null) PathView._(id: r.parent!),
            ElevatedButton(
              child: Text(r.parent == null ? "/" : r.name),
              onPressed: () {
                context.pushNamed('folder', pathParameters: {'id': r.id});
              },
            ),
          ],
        );
      },
    );
  }
}
