import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

sealed class AboutUtils {
  const AboutUtils._();

  static void show(BuildContext context) async {
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
                TextSpan(text: ' or (at your option) any later version'),
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
}
