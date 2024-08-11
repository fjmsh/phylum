import 'package:flutter/material.dart';
import 'package:phylum/folder_view.dart';
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
        body: FolderView(id: account.userHome));
  }
}
