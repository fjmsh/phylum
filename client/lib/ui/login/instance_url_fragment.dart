import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/login/instance_config.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'package:phylum/util/base_uri/base_uri_stub.dart'
    if (dart.library.js_interop) 'package:phylum/util/base_uri/base_uri_web.dart';
import 'login_controller.dart';

class InstanceUrlFragment extends StatefulWidget {
  final bool readonly;

  const InstanceUrlFragment({super.key, required this.readonly});

  @override
  State<InstanceUrlFragment> createState() => _InstanceUrlFragmentState();
}

class _InstanceUrlFragmentState extends State<InstanceUrlFragment> {
  final _instanceUrlController =
      TextEditingController(text: webAppBaseUri?.toString() ?? '');
  bool connecting = false;

  @override
  void initState() {
    super.initState();
    if (webAppBaseUri != null) {
      _instanceUrlController.text = webAppBaseUri!.toString();
      WidgetsBinding.instance.addPostFrameCallback((d) {
        connect(context);
      });
    } else {
      _instanceUrlController.text =
          context.read<LoginState>().instanceUrl?.toString() ??
              webAppBaseUri?.toString() ??
              '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: widget.readonly ? 6 : 18,
      children: [
        TextFormField(
          key: ValueKey('instanceUrl'),
          decoration: InputDecoration(
            label: const Text('Instance URL'),
            hintText: 'https://phylum.example.com',
            prefixIcon: Icon(Icons.storage),
            suffixIcon: (widget.readonly)
                ? IconButton(
                    onPressed: () => context.read<LoginController>().reset(),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.edit),
                    iconSize: 18,
                  )
                : null,
          ),
          readOnly: widget.readonly && !connecting,
          autofocus: !widget.readonly,
          autofillHints: const [AutofillHints.url],
          keyboardType: TextInputType.url,
          controller: _instanceUrlController,
          onFieldSubmitted: (value) => connect(context),
        ),
        if (widget.readonly)
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
      final c = Completer();
      Future.delayed(Duration(seconds: 2), () {
        c.complete(null);
      });
      await c.future;
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
