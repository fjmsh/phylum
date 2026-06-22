import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/settings/settings.dart';

import 'downloads_pane.dart';

class DownloadsSettings extends Settings {
  @override
  IconData get icon => Icons.download;

  @override
  String get title => 'Downloads';

  @override
  List<StateNotifierProvider> get providers => const [];

  const DownloadsSettings();

  @override
  Widget buildWithoutScaffold(BuildContext context) => const DownloadsPane();
}
