import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

class PathView extends StatefulWidget {
  final String id;

  const PathView._({required this.id}) : super();

  static Widget create(String id) {
    return SizedBox(
      height: 56,
      child: Align(alignment: Alignment.centerLeft, child: PathView._(id: id)),
    );
  }

  @override
  State<PathView> createState() => _PathViewState();
}

class _PathViewState extends State<PathView> {
  late String id;
  StreamSubscription? sub;
  Iterable<ParentsResult>? ancestors;

  @override
  void initState() {
    super.initState();
    id = widget.id;
    updateStream();
  }

  @override
  void didUpdateWidget(covariant PathView oldWidget) {
    super.didUpdateWidget(oldWidget);
    id = widget.id;
    updateStream();
  }

  void updateStream() {
    sub?.cancel();
    sub = context.read<PhylumAccount>().db.parents(id).watch().listen((data) {
      setState(() {
        ancestors = data.reversed;
      });
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ancestors == null) {
      return const Text('Loading');
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in ancestors!)
          ElevatedButton(
            child: Text(r.parent == null ? "/" : r.name),
            onPressed: () {
              context.goNamed('folder', pathParameters: {'id': r.id});
            },
          ),
      ],
    );
  }
}
