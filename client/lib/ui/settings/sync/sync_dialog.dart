import 'package:flutter/material.dart';

import 'sliver_actions.dart';
import 'sliver_paused_unreachable.dart';

class SyncDialog extends StatelessWidget {
  const SyncDialog({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomScrollView(slivers: [PausedOfflineSliver(), ActionsSliver()]);
}
