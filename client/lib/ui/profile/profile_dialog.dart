import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phylum/libphylum/phylum_account.dart';
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
                      child: Text(
                        account.userRepository.getUserDisplayName(account.user.id),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, size: 18),
                      splashRadius: 6,
                      padding: EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                      constraints: BoxConstraints(),
                      onPressed: () async {
                        final name = await showInputDialog(
                          context,
                          title: 'Change Name',
                          labelText: 'Name',
                          preset: account.user.name,
                        );
                        if (name == null) return;
                      },
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
}
