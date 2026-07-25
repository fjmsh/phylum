import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login_controller.dart';

class InstanceUrlField extends StatelessWidget {
  const InstanceUrlField({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        TextFormField(
          key: ValueKey('instanceUrl'),
          decoration: InputDecoration(
            label: const Text('Instance URL'),
            hintText: 'https://phylum.example.com',
            prefixIcon: Icon(Icons.storage),
            suffixIcon: instanceUrlFixed
                ? null
                : IconButton(
                    onPressed: () => context.read<LoginController>().reset(),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.edit),
                    iconSize: 18,
                  ),
          ),
          readOnly: true,
          keyboardType: TextInputType.url,
          initialValue: context.read<LoginState>().instanceUrl.toString(),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 48, right: 48),
          child: Divider(),
        ),
      ],
    );
  }
}
