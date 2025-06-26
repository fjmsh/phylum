import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/login/instance_config.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:uri/uri.dart';

class InstanceUrlFragment extends StatefulWidget {
  final Function(InstanceConfig) onInstanceSelected;

  const InstanceUrlFragment({super.key, required this.onInstanceSelected});

  @override
  State<InstanceUrlFragment> createState() => _InstanceUrlFragmentState();
}

class _InstanceUrlFragmentState extends State<InstanceUrlFragment> {
  Uri? _url;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12.0,
      children: [
        TextField(
          decoration: InputDecoration(
            label: const Text('Instance URL'),
            hintText: 'https://phylum.example.com',
          ),
          autofillHints: const [AutofillHints.url],
          keyboardType: TextInputType.url,
          onChanged: (value) {
            final Uri? url;
            if (kIsWeb) {
              url = value == '' ? Uri() : Uri.tryParse(value);
            } else {
              final tempUrl = Uri.tryParse(value);
              if (tempUrl != null && (kIsWeb || tempUrl.hasAuthority && tempUrl.hasScheme)) {
                url = tempUrl;
              } else {
                url = null;
              }
            }
            setState(() => _url = url);
          },
          onSubmitted: _url == null ? null : (value) => checkConfig(_url!),
        ),
        ElevatedButton(onPressed: _url == null ? null : () => checkConfig(_url!), child: Text('Next'))
      ],
    );
  }

  void checkConfig(Uri url) async {
    final nav = Navigator.of(context);
    try {
      showProgressDialog(context, barrierDismissible: false, message: 'Getting login configuration');
      final config = await findInstanceConfig(url);
      nav.pop();
      if (config == null) {
        if (mounted) {
          showAlertDialog(context, message: 'No server found at $url');
        }
      } else {
        widget.onInstanceSelected(config);
      }
    } catch (e) {
      nav.pop();
      if (mounted) {
        showAlertDialog(context, title: 'Error getting configuration', message: e.toString());
      }
    }
  }

  Future<InstanceConfig?> findInstanceConfig(Uri url) async {
    // _url == null ? null : (value) => widget.onSubmitted(_url!),
    List<String> segments = url.pathSegments;
    while (true) {
      final builder = UriBuilder.fromUri(url);
      builder.path = segments.join('/');
      final config = await getInstanceConfig(builder.build());
      if (config != null) {
        return config;
      }
      if (segments.isEmpty) {
        return null;
      }
      segments = segments.sublist(0, segments.length - 1);
    }
  }

  Future<InstanceConfig?> getInstanceConfig(Uri url) async {
    try {
      final builder = UriBuilder.fromUri(url);
      builder.path = '${builder.path}/api/v1/auth/config';
      final response = await Client().send(Request('GET', builder.build()));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseString = await response.stream.bytesToString();
        return InstanceConfig.fromResponse(url, responseString);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
