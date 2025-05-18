import 'package:flutter/material.dart';

class LogoRow extends StatelessWidget {
  const LogoRow({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
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
        Text('PHYLUM', style: textTheme.headlineSmall),
      ],
    );
  }
}
