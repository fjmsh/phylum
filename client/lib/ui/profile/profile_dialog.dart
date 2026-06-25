import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/update_user_name_request.dart';
import 'package:phylum/libphylum/requests/change_password_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/common/responsive_dialog.dart';
import 'package:phylum/ui/settings/security/sessions_keys_pane.dart';
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
        providers: [Provider.value(value: account)],
        child: AlertDialog(
          insetPadding: const EdgeInsets.all(12),
          contentPadding: const EdgeInsets.all(6),
          scrollable: true,
          content: SizedBox(width: 420, child: ProfileDialog._()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CloseButton(),
              const LogoRow(),
              IconButton(
                onPressed: () => _showAboutDialog(context),
                icon: Icon(Icons.help_outline),
              ),
            ],
          ),
        ),
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
                            style: user.name.isEmpty
                                ? TextStyle(fontStyle: FontStyle.italic)
                                : null,
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      splashRadius: 6,
                      padding: const EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 6,
                      ),
                      constraints: const BoxConstraints(),
                      onPressed: () => editName(context),
                    ),
                  ],
                ),
                subtitle: Text(
                  context.read<PhylumAccount>().apiClient.serverUrl.host,
                ),
              ),
              Divider(thickness: 2, height: 2),
              ListTile(
                visualDensity: VisualDensity.compact,
                leading: Icon(Icons.password),
                title: Text('Change Password'),
                onTap: () => changePassword(context),
              ),
              Divider(thickness: 1, height: 1),
              ListTile(
                visualDensity: VisualDensity.compact,
                leading: Icon(Icons.key),
                title: Text('API Keys'),
                onTap: () => showReponsiveDialog(
                  context,
                  'API Keys',
                  (context) => const SessionsKeysView(),
                ),
              ),
              Divider(thickness: 1, height: 1),
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
      ],
    );
  }

  void _showAboutDialog(BuildContext context) async {
    final account = context.read<PhylumAccount>();
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationIcon: Image(
        image: AssetImage('assets/images/logo.png'),
        height: 48,
        width: 48,
        fit: BoxFit.contain,
      ),
      applicationVersion:
          '${packageInfo.version} (Server Version ${account.config.version})',
      children: [
        SizedBox(
          width: 360,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'Phylum is Free Software offered under the '),
                TextSpan(
                  text: 'GNU AGPL V3.0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => launchUrl(
                      Uri.parse(
                        'https://www.gnu.org/licenses/agpl-3.0.en.html',
                      ),
                    ),
                ),
              ],
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: RichText(
            text: TextSpan(
              text: 'View Source on Codeberg',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () =>
                    launchUrl(Uri.parse('https://codeberg.org/shroff/phylum')),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: RichText(
            text: TextSpan(
              text: 'Get help on Matrix',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchUrl(
                  Uri.parse('https://matrix.to/#/#phylum_cloud:matrix.org'),
                ),
            ),
          ),
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

  void changePassword(BuildContext context) async {
    final account = context.read<PhylumAccount>();
    bool passwordsVisible = false;
    String oldPassword = '';
    String newPassword = '';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(label: Text('Current Password')),
                obscureText: !passwordsVisible,
                enableSuggestions: false,
                autocorrect: false,
                autofocus: true,
                autofillHints: const [AutofillHints.password],
                keyboardType: TextInputType.visiblePassword,
                onChanged: (value) => oldPassword = value,
              ),
              TextField(
                decoration: InputDecoration(label: Text('New Password')),
                obscureText: !passwordsVisible,
                enableSuggestions: false,
                autocorrect: false,
                autofocus: true,
                autofillHints: const [AutofillHints.password],
                keyboardType: TextInputType.visiblePassword,
                onChanged: (value) => newPassword = value,
              ),
              Row(
                children: [
                  Checkbox(
                    value: passwordsVisible,
                    onChanged: (value) =>
                        setState(() => passwordsVisible = value!),
                  ),
                  const Text('Show Passwords'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              autofocus: true,
              child: Text('OK'),
              onPressed: () async {
                showProgressDialog(context, title: 'Changing Password');

                final response = await account.apiClient.sendRequest(
                  ChangePasswordRequest(
                    email: account.user.email,
                    oldPassword: oldPassword,
                    newPassword: newPassword,
                  ),
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (response is ApiErrorResponse) {
                    showAlertDialog(context, message: response.description);
                  } else if (response is ApiUnreachableError) {
                    showAlertDialog(context, message: 'Server Unreachable');
                  } else {
                    Navigator.of(context).pop();
                    showAlertDialog(context, message: 'Password Changed');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
