import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/login/instance_info.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/logging/logging.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import '../login_controller.dart';

class InstanceUrlScreen extends StatefulWidget {
  final void Function(InstanceInfo) onInstanceConnected;

  const InstanceUrlScreen({super.key, required this.onInstanceConnected});

  @override
  State<InstanceUrlScreen> createState() => _InstanceUrlScreenState();
}

class _InstanceUrlScreenState extends State<InstanceUrlScreen> {
  final _instanceUrlController = TextEditingController();
  bool connecting = false;

  @override
  void initState() {
    super.initState();
    final instanceUrl = context.read<LoginState>().instanceUrl;
    _instanceUrlController.text = instanceUrl?.toString() ?? '';

    if (instanceUrlFixed && instanceUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((d) {
        connect(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        TextFormField(
          key: ValueKey('instanceUrl'),
          decoration: InputDecoration(
            label: const Text('Instance URL'),
            hintText: 'https://phylum.example.com',
            prefixIcon: Icon(Icons.storage),
          ),
          readOnly: instanceUrlFixed || connecting,
          autofocus: !instanceUrlFixed,
          autofillHints: const [AutofillHints.url],
          keyboardType: TextInputType.url,
          controller: _instanceUrlController,
          onFieldSubmitted: (value) => connect(context),
        ),
        ValueListenableBuilder(
          valueListenable: _instanceUrlController,
          builder: (_, instanceUrl, _) {
            final uri = Uri.tryParse(instanceUrl.text);
            final uriValid = uri != null && uri.hasScheme && uri.hasAuthority;
            return ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              label: Text(connecting ? 'Getting Configuration' : 'Login'),
              icon: connecting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(Icons.arrow_forward),
              iconAlignment: IconAlignment.end,
              onPressed: connecting || !uriValid
                  ? null
                  : () => connect(context),
            );
          },
        ),
      ],
    );
  }

  void connect(BuildContext context) async {
    if (connecting) return;
    final uri = Uri.tryParse(_instanceUrlController.text);
    final uriValid = uri != null && uri.hasScheme && uri.hasAuthority;
    if (!uriValid) return;

    setState(() => connecting = true);
    try {
      final info = await findInfo(uri);
      if (!context.mounted) return;
      if (info == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No server found at $uri')));
      } else {
        final setupConfig = info.setupConfig;
        if (setupConfig != null) {
          final delegate = context.read<PhylumRouterDelegate>();
          final confirm =
              await showAlertDialog(
                context,
                title: 'Configure Server?',
                message: 'The server at $uri is awaiting setup.',
                positiveText: 'Yes',
                negativeText: 'No',
              ) ??
              false;
          if (!confirm) return;
          delegate.go(
            SetupRoute(instanceUrl: info.url.toString(), config: setupConfig),
          );
        } else {
          context.read<LoginController>().instanceInfo = info;
          widget.onInstanceConnected(info);
        }
      }
    } catch (e, stack) {
      if (context.mounted) {
        showAlertDialog(
          context,
          title: 'Error getting server info',
          message: e.toString(),
        );
      }
      Log.warn('Error Parsing Response', e, stack);
    } finally {
      setState(() {
        connecting = false;
      });
    }
  }

  Future<InstanceInfo?> findInfo(Uri url) async {
    final builder = UriBuilder.fromUri(url);
    // Strip trailing slash
    if (builder.path.endsWith('/')) {
      builder.path = builder.path.substring(0, builder.path.length - 1);
      url = builder.build();
    }
    builder.path = '${builder.path}/api/v1/info';
    final result = await sendRequest(Request('GET', builder.build()));
    if (result is SuccessResponse) {
      return InstanceInfo.fromResponse(url, result.responseString);
    }
    return null;
  }
}
