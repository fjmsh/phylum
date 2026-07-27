import 'package:flutter/material.dart';
import 'package:phylum/ui/settings/config/remote_config.dart';
import 'package:phylum/ui/settings/config/remote_config_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

typedef ConfigWidgetBuilder<T extends ConfigFields> =
    Widget Function(BuildContext, T);

class RemoteConfigPane<T extends ConfigFields>
    extends SingleChildStatefulWidget {
  const RemoteConfigPane({super.key, required super.child});

  @override
  State<RemoteConfigPane<T>> createState() => _RemoteConfigPaneState();
}

class _RemoteConfigPaneState<T extends ConfigFields>
    extends SingleChildState<RemoteConfigPane<T>> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<RemoteConfigController<T>>().maybeFetch(),
    );
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    final state = context.watch<RemoteConfigState<T>>();

    if (state is RemoteConfigStateLoading<T>) {
      return const Center(child: CircularProgressIndicator());
    }

    return switch (state) {
      RemoteConfigStateWaiting<T>() => buildWaiting(context, state),
      RemoteConfigStateLoading<T>() => const Center(
        child: CircularProgressIndicator(),
      ),
      RemoteConfigStateLoaded<T>() => SingleChildScrollView(child: child),
    };
  }

  Widget buildWaiting(BuildContext context, RemoteConfigStateWaiting<T> state) {
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
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
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
}
