import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/login/instance_config.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'login_controller.dart';

class LoginInstanceUrl extends StatefulWidget {
  final bool display;

  const LoginInstanceUrl({super.key, required this.display});

  @override
  State<LoginInstanceUrl> createState() => _LoginInstanceUrlState();
}

class _LoginInstanceUrlState extends State<LoginInstanceUrl> {
  final _instanceUrlController = TextEditingController();
  bool connecting = false;

  bool get readonly => widget.display || instanceUrlFixed;

  @override
  void initState() {
    super.initState();
    final instanceUrl = context.read<LoginState>().instanceUrl;
    _instanceUrlController.text = instanceUrl?.toString() ?? '';

    if (instanceUrlFixed && instanceUrl != null && !widget.display) {
      WidgetsBinding.instance.addPostFrameCallback((d) {
        connect(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: widget.display ? 6 : 18,
      children: [
        TextFormField(
          key: ValueKey('instanceUrl'),
          decoration: InputDecoration(
            label: const Text('Instance URL'),
            hintText: 'https://phylum.example.com',
            prefixIcon: Icon(Icons.storage),
            suffixIcon: widget.display && !instanceUrlFixed
                ? IconButton(
                    onPressed: () => context.read<LoginController>().reset(),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.edit),
                    iconSize: 18,
                  )
                : null,
          ),
          readOnly: readonly || connecting,
          autofocus: !readonly,
          autofillHints: const [AutofillHints.url],
          keyboardType: TextInputType.url,
          controller: _instanceUrlController,
          onFieldSubmitted: (value) => connect(context),
        ),
        if (widget.display)
          const Padding(
            padding: EdgeInsets.only(left: 48, right: 48),
            child: Divider(),
          )
        else
          ValueListenableBuilder(
              valueListenable: _instanceUrlController,
              builder: (_, instanceUrl, __) {
                final uri = Uri.tryParse(instanceUrl.text);
                final uriValid =
                    uri != null && uri.hasScheme && uri.hasAuthority;
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
                              child: CircularProgressIndicator(
                            strokeWidth: 2,
                          )),
                        )
                      : Icon(Icons.arrow_forward),
                  iconAlignment: IconAlignment.end,
                  onPressed:
                      connecting || !uriValid ? null : () => connect(context),
                );
              }),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No server found at $uri')));
      } else {
        if (info.needsSetup) {
          final delegate = context.read<PhylumRouterDelegate>();
          final confirm = await showAlertDialog(
                context,
                title: 'Configure Server?',
                message: 'The server at $uri is needs to be set up.',
                positiveText: 'Yes',
                negativeText: 'No',
              ) ??
              false;
          if (!confirm) return;
          delegate.go(SetupRoute(instanceUrl: info.url.toString()));
        } else {
          context.read<LoginController>().instanceInfo = info;
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAlertDialog(context,
            title: 'Error getting server info', message: e.toString());
      }
    } finally {
      setState(() {
        connecting = false;
      });
    }
  }

  Future<InstanceInfo?> findInfo(Uri url) async {
    // _url == null ? null : (value) => widget.onSubmitted(_url!),
    List<String> segments = url.pathSegments;
    while (true) {
      final builder = UriBuilder.fromUri(url);
      builder.path = segments.join('/');
      final config = await fetchInfo(builder.build());
      if (config != null) {
        return config;
      }
      if (segments.isEmpty) {
        return null;
      }
      segments = segments.sublist(0, segments.length - 1);
    }
  }

  Future<InstanceInfo?> fetchInfo(Uri url) async {
    try {
      final builder = UriBuilder.fromUri(url);
      builder.path = '${builder.path}/api/v1/info';
      final response = await Client().send(Request('GET', builder.build()));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseString = await response.stream.bytesToString();
        return InstanceInfo.fromResponse(url, responseString);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
