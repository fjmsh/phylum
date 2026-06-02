import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/login/instance_config.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import '../../util/base_uri/base_uri_stub.dart'
    if (dart.library.js_interop) 'base_uri_web.dart';
import 'login_controller.dart';

class InstanceUrlFragment extends StatefulWidget {
  final bool readonly;

  const InstanceUrlFragment({super.key, required this.readonly});

  @override
  State<InstanceUrlFragment> createState() => _InstanceUrlFragmentState();
}

class _InstanceUrlFragmentState extends State<InstanceUrlFragment> {
  Uri? _url = webAppBaseUri;

  @override
  void initState() {
    super.initState();
    _url = context.read<LoginState>().instanceUrl ?? webAppBaseUri;
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
          initialValue: _url?.toString() ?? '',
          readOnly: widget.readonly,
          autofocus: true,
          autofillHints: const [AutofillHints.url],
          keyboardType: TextInputType.url,
          onChanged: (value) {
            var url = value == '' ? webAppBaseUri : Uri.tryParse(value);
            if (url != null && (!url.hasAuthority || !url.hasScheme)) {
              url = null;
            }
            setState(() => _url = url);
          },
          onFieldSubmitted: _url == null ? null : (value) => checkConfig(_url!),
        ),
        if (widget.readonly)
          const Padding(
            padding: EdgeInsets.only(left: 48, right: 48),
            child: Divider(),
          )
        else
          ElevatedButton.icon(
            label: Text('Connect'),
            icon: Icon(Icons.arrow_forward),
            iconAlignment: IconAlignment.end,
            onPressed: _url == null ? null : () => checkConfig(_url!),
          ),
      ],
    );
  }

  void checkConfig(Uri url) async {
    final nav = Navigator.of(context);
    try {
      showProgressDialog(context,
          barrierDismissible: false, message: 'Getting login configuration');
      final info = await findInstanceInfo(url);
      nav.pop();
      if (info == null) {
        if (mounted) {
          showAlertDialog(context, message: 'No server found at $url');
        }
      } else {
        if (!mounted) return;
        if (info.needsSetup) {
          final delegate = context.read<PhylumRouterDelegate>();
          final confirm = await showAlertDialog(
                context,
                title: 'Configure Server?',
                message: 'The server at $url is needs to be set up.',
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
      nav.pop();
      if (mounted) {
        showAlertDialog(context,
            title: 'Error getting server info', message: e.toString());
      }
    }
  }

  Future<InstanceInfo?> findInstanceInfo(Uri url) async {
    // _url == null ? null : (value) => widget.onSubmitted(_url!),
    List<String> segments = url.pathSegments;
    while (true) {
      final builder = UriBuilder.fromUri(url);
      builder.path = segments.join('/');
      final config = await getInstanceInfo(builder.build());
      if (config != null) {
        return config;
      }
      if (segments.isEmpty) {
        return null;
      }
      segments = segments.sublist(0, segments.length - 1);
    }
  }

  Future<InstanceInfo?> getInstanceInfo(Uri url) async {
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
