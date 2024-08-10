import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phylum'),
      ),
      body: Center(
        child: Column(
          children: [
            Text(account.userName),
            Text(account.userEmail),
            Text(account.userHome),
          ],
        ),
      ),
    );
  }
}
