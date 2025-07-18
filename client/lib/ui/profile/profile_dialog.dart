import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/update_user_name_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/profile/profile_view.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog._();

  static void show(BuildContext context) {
    final account = context.read<PhylumAccount>();
    showDialog(
      context: context,
      builder: (context) => MultiProvider(
        providers: [
          Provider.value(value: account),
        ],
        child: AlertDialog(
          scrollable: true,
          content: SizedBox(width: 360, child: ProfileDialog._()),
          actions: [
            ElevatedButton(onPressed: Navigator.of(context).pop, child: Text('OK')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    return Column(
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: ProfileView(name: account.user.name, email: account.user.email),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: StreamBuilder(
                          stream: account.userNotifier.stream,
                          initialData: account.user,
                          builder: (context, snapshot) {
                            return Text(
                              account.userRepository.getUserDisplayName(account.user.id),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            );
                          }),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, size: 18),
                      splashRadius: 6,
                      padding: EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                      constraints: BoxConstraints(),
                      onPressed: () => editName(context),
                    ),
                  ],
                ),
                subtitle: Text(context.read<PhylumAccount>().apiClient.serverUrl.host),
              ),
              Divider(thickness: 2),
              const ListTile(
                visualDensity: VisualDensity.compact,
                leading: Icon(Icons.password),
                title: Text('Change Password'),
              ),
              ListTile(
                visualDensity: VisualDensity.compact,
                leading: const Icon(Icons.logout),
                title: const Text('Log Out'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<PhylumAccount>().close(clearData: true);
                },
              ),
            ],
          ),
        ),
        const ListTile(
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.settings),
          title: Text('Settings'),
        ),
        ListTile(
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.help),
          title: const Text('About'),
          onTap: () async {
            final info = await PackageInfo.fromPlatform();
            if (!context.mounted) return;
            showAboutDialog(
              context: context,
              applicationVersion: '${info.packageName} - ${info.version} (${info.buildNumber})',
            );
          },
        ),
      ],
    );
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

    final response = await account.apiClient.sendRequest(
      EditUserNameRequest(name),
      (request, response) => parseJsonMapResponse(response, EmptyResponse.fromResponse),
    );

    nav.pop();
    if (response is ApiSuccessResponse) {
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
