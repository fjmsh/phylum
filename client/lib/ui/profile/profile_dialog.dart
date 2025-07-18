import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/update_user_name_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/profile/profile_view.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
          insetPadding: const EdgeInsets.all(12),
          contentPadding: const EdgeInsets.all(6),
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
                leading: ProfileView(),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: StreamBuilder(
                          stream: account.userNotifier.stream,
                          initialData: account.user,
                          builder: (context, snapshot) {
                            final user = snapshot.data!;
                            return Text(
                              user.name.isEmpty ? user.email : user.name,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: user.name.isEmpty ? TextStyle(fontStyle: FontStyle.italic) : null,
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
          title: const Text('About Phylum'),
          onTap: () async {
            final info = await PackageInfo.fromPlatform();
            if (!context.mounted) return;
            showAboutDialog(
              context: context,
              applicationIcon: Image(
                image: AssetImage('assets/images/logo.png'),
                height: 48,
                width: 48,
                fit: BoxFit.contain,
              ),
              applicationVersion: '${info.packageName} - ${info.version} (${info.buildNumber})',
              children: [
                Text('Phylum is Free Software offered under the GNU AGPL V3.0'),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: RichText(
                    text: TextSpan(
                      text: 'View source on Codeberg',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(Uri.parse('https://codeberg.org/shroff/phylum')),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: RichText(
                    text: TextSpan(
                      text: 'Get help on Matrix',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(Uri.parse('https://matrix.to/#/#phylum_cloud:matrix.org')),
                    ),
                  ),
                ),
              ],
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
      (request, response) => parseJsonMapResponse(response, UserResponse.fromResponse),
    );

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
