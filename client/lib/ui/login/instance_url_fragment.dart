import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class InstanceUrlFragment extends StatefulWidget {
  final Function(Uri) onSubmitted;

  const InstanceUrlFragment({super.key, required this.onSubmitted});

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
            hintText: 'http://localhost:2448/',
          ),
          keyboardType: TextInputType.url,
          onChanged: (value) {
            final Uri? url;
            if (kIsWeb) {
              url = value == '' ? Uri() : Uri.tryParse(value);
            } else {
              final tempUrl = Uri.tryParse(value);
              if (tempUrl != null && tempUrl.hasAuthority && tempUrl.hasScheme) {
                url = tempUrl;
              } else {
                url = null;
              }
            }
            setState(() => _url = url);
          },
          onSubmitted: _url == null ? null : (value) => widget.onSubmitted(_url!),
        ),
        ElevatedButton(onPressed: _url == null ? null : () => widget.onSubmitted(_url!), child: Text('Next'))
      ],
    );
  }
}
