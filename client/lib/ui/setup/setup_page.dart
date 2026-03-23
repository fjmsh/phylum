import 'package:flutter/material.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/setup/setup_db_fragment.dart';
import 'package:phylum/ui/setup/setup_fragment.dart';
import 'package:provider/provider.dart';

class SetupPage extends StatefulWidget {
  final String instanceUrl;

  const SetupPage({super.key, required this.instanceUrl});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final dbFragmentKey = GlobalKey<SetupDbFragmentState>();
  GlobalKey<SetupFragmentState>? currentKey;
  DbConfig? _dbConfig;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instance Setup'),
        leading: CloseButton(
          onPressed: () => context.read<PhylumRouterDelegate>().go(const ExplorerRouteHome()),
        ),
        actions: [
          TextButton(
              onPressed: () {
                currentKey?.currentState?.handleNextPress();
              },
              child: Text('NEXT'))
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    currentKey = dbFragmentKey;
    return SetupDbFragment(key: dbFragmentKey);
  }

  void handleDbConfig(DbConfig config) {
    setState(() {
      _dbConfig = config;
    });
  }
}
