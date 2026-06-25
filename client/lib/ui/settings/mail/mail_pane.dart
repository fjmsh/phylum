import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/settings/mail/mail_config_controller.dart';
import 'package:provider/provider.dart';

class MailPane extends StatefulWidget {
  const MailPane({super.key});

  @override
  State<MailPane> createState() => _MailPaneState();
}

class _MailPaneState extends State<MailPane> {
  @override
  void initState() {
    super.initState();
    context.read<MailConfigController>().maybeFetch();
  }

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    final state = context.watch<MailConfigState>();
    final config = state.config;
    if (config == null) {
      if (state.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 18,
        children: [
          if (state.error != null)
            Text('Error loading Mail Config: ${state.error}'),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            onPressed: () {
              context.read<MailConfigController>().fetch();
            },
            child: Text(state.error == null ? 'Load Mail Config' : 'Retry'),
          ),
        ],
      );
    }
    return Placeholder();
  }
}
