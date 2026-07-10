import 'package:flutter/material.dart';
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
    return const Placeholder();
  }
}
