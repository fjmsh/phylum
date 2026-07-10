import 'package:flutter/material.dart';
import 'package:phylum/ui/settings/auth/auth_config_form.dart';
import 'package:provider/provider.dart';

import 'auth_config_controller.dart';

class AuthPane extends StatefulWidget {
  const AuthPane({super.key});

  @override
  State<AuthPane> createState() => _AuthPaneState();
}

class _AuthPaneState extends State<AuthPane> {
  @override
  void initState() {
    super.initState();
    context.read<AuthConfigController>().maybeFetch();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthConfigState>();
    final config = state.config;
    if (config == null) {
      if (state.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Column(
          mainAxisAlignment: .center,
          crossAxisAlignment: .center,
          spacing: 18,
          children: [
            if (state.error != null)
              Text('Error loading Mail Config: ${state.error}'),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer,
              ),
              onPressed: () {
                context.read<AuthConfigController>().fetch();
              },
              child: Text(state.error == null ? 'Load Mail Config' : 'Retry'),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(child: const AuthConfigForm());
  }
}
