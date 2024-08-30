import 'package:flutter/material.dart';

enum ResourceOption {
  rename(Icons.edit, 'Rename'),
  delete(Icons.delete, 'Delete');

  const ResourceOption(this.icon, this.text);

  final IconData icon;
  final String text;
}

class ResourceOptionsList extends StatelessWidget {
  const ResourceOptionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        for (final o in ResourceOption.values)
          ListTile(
            leading: Icon(o.icon),
            title: Text(o.text),
            onTap: () => Navigator.of(context).pop(o),
          ),
      ],
    );
  }
}
