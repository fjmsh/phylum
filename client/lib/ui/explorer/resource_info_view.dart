import 'package:flutter/material.dart';

class ResourceInfoView extends StatefulWidget {
  final String folderId;

  const ResourceInfoView({super.key, required this.folderId});

  @override
  State<ResourceInfoView> createState() => _ResourceInfoViewState();
}

class _ResourceInfoViewState extends State<ResourceInfoView> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [Text('Loading')],
    );
  }
}
