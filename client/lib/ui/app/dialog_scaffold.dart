import 'package:flutter/material.dart';
import 'package:phylum/ui/common/logo_row.dart';

class PhylumDialogScaffold extends StatelessWidget {
  final Widget child;

  const PhylumDialogScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Card(
        margin: EdgeInsets.all(16.0),
        child: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(padding: EdgeInsets.only(bottom: 12), child: LogoRow()),
                child,
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
