import 'package:flutter/material.dart';

class PhylumDialogScaffold extends StatelessWidget {
  final Widget child;
  const PhylumDialogScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6.0),
                    child: Image(
                      image: AssetImage('assets/images/logo.png'),
                      height: 36,
                      width: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Text('PHYLUM', style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    ));
  }
}
