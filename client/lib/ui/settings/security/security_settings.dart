import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/settings/settings.dart';

class SecuritySettings extends Settings {
  @override
  IconData get icon => Icons.security;

  @override
  String get title => 'Security';

  const SecuritySettings();

  @override
  List<StateNotifierProvider> get providers => const [];

  @override
  Widget buildWithScaffold(BuildContext context) => Placeholder();

  @override
  Widget buildWithoutScaffold(BuildContext context) => Placeholder();
}
