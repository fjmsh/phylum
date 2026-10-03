import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/settings/settings.dart';
import 'package:phylum/ui/settings/sync/sliver_actions.dart';
import 'package:phylum/ui/settings/sync/sliver_paused_unreachable.dart';

class SyncSettings extends Settings {
  @override
  IconData get icon => Icons.sync;

  @override
  String get title => 'Sync';

  @override
  String get slug => 'sync';

  const SyncSettings();

  @override
  List<StateNotifierProvider> get providers => const [];

  @override
  Widget buildWithoutScaffold(BuildContext context) =>
      const CustomScrollView(slivers: [PausedOfflineSliver(), ActionsSliver()]);
}
