import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/update_user_name_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/settings/settings.dart';
import 'package:phylum/util/dialogs.dart';
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
    final account = context.watch<PhylumAccount>();
    return StateNotifierBuilder(
        builder: (context, user, child) {
          return ListView(
            children: [
              ListTile(
                leading: Icon(Icons.storage),
                title: Text('Instance URL'),
                subtitle: Text(account.apiClient.serverUrl.toString()),
              ),
              ListTile(
                leading: Icon(Icons.email),
                title: Text('Email'),
                subtitle: Text(user.email),
              ),
              ListTile(
                leading: Icon(Icons.perm_identity),
                title: Text('Name'),
                subtitle: Text(user.name),
                trailing: Icon(Icons.edit),
                onTap: () => editName(context),
              ),
            ],
          );
        },
        stateNotifier: account.userNotifier);
  }

  void editName(BuildContext context) async {
    final account = context.read<PhylumAccount>();
    final name = await showInputDialog(
      context,
      title: 'Change Name',
      labelText: 'Name',
      preset: account.user.name,
    );
    if (name == null || !context.mounted) return;

    final nav = Navigator.of(context);
    showProgressDialog(context, title: 'Updating Name');

    final response =
        await account.apiClient.sendRequest(EditUserNameRequest(name));

    nav.pop();
    if (response is UserResponse) {
      account.user = account.user.copyWith(name: name);
    } else if (response is ApiErrorResponse) {
      if (context.mounted) {
        showAlertDialog(context, message: response.description);
      }
    } else if (response is ApiUnreachableError) {
      if (context.mounted) {
        showAlertDialog(context, message: 'Server Unreachable');
      }
    }
  }
}
