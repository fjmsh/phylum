import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    final account = context.read<PhylumAccount>();
    WidgetsBinding.instance.addPostFrameCallback((t) {
      context.replace('/dir/${account.userHome}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
