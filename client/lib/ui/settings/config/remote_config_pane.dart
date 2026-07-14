import 'package:flutter/material.dart';
import 'package:phylum/ui/settings/config/remote_config_controller.dart';
import 'package:provider/provider.dart';

class RemoteConfigPane<T> extends StatefulWidget {
  final Widget child;

  const RemoteConfigPane({super.key, required this.child});

  @override
  State<RemoteConfigPane<T>> createState() => _RemoteConfigPaneState();
}

class _RemoteConfigPaneState<T> extends State<RemoteConfigPane<T>> {
  late Widget child;

  @override
  void initState() {
    super.initState();
    child = widget.child;
    context.read<RemoteConfigController<T>>().maybeFetch();
  }

  @override
  void didUpdateWidget(covariant RemoteConfigPane<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    child = widget.child;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RemoteConfigState<T>>();
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
                context.read<RemoteConfigController<T>>().fetch();
              },
              child: Text(state.error == null ? 'Load Config' : 'Retry'),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(child: child);
  }
}
