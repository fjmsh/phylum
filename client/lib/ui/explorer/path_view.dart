import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: PathView._(id: id),
        ),
      ),
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
      SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription(
        label: "${data[0].name == "" ? "/" : data[0].name} | Phylum",
      ));
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
    final ancestors = this.ancestors;
    if (ancestors == null) {
      return const Text('');
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in ancestors)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            margin: EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              onTap: r.id == widget.id
                  ? null
                  : () {
                      context.goNamed('folder', pathParameters: {'id': r.id});
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  r.parent == null ? "/" : r.name,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
