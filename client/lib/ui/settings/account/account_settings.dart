import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/settings/settings.dart';
import 'package:provider/provider.dart';

class AccountSettings extends Settings {
  @override
  IconData get icon => Icons.person;

  @override
  String get title => 'Account';

  const AccountSettings();

  @override
  List<StateNotifierProvider> get providers => const [];

  @override
  Widget buildWithoutScaffold(BuildContext context) => AccountSettingsPane();
}

class AccountSettingsPane extends StatelessWidget {
  const AccountSettingsPane({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: Icon(Icons.storage),
          title: Text('Instance URL'),
          subtitle: Text(
              context.read<PhylumAccount>().apiClient.serverUrl.toString()),
        ),
        ListTile(
          leading: Icon(Icons.email),
          title: Text('Email'),
          subtitle: Text(context.read<PhylumAccount>().user.email),
        ),
        ListTile(
          leading: Icon(Icons.perm_identity),
          title: Text('Name'),
          subtitle: Text(context.read<PhylumAccount>().user.name),
        ),
      ],
    );
  }
}
