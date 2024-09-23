import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

class ActionQueueList extends StatelessWidget {
  const ActionQueueList({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = context.select<ApiActionQueueState, Iterable<ApiAction>>((state) => state.actions.keys).toList(growable: false);
    return ListView.builder(shrinkWrap: true, itemCount: queue.length, itemBuilder: (context, i) => ActionView(action: queue[i]));
  }
}

class ActionView extends StatelessWidget {
  final ApiAction action;
  ActionView({required this.action}) : super(key: ValueKey(action.key));

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    final state = context.select<ApiActionQueueState, ActionState>((state) => state.actions[action]!);
    return ListTile(
      title: Text(action.generateDescription(account)),
      subtitle: Text(state.toString()),
    );
  }
}
