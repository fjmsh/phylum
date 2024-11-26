import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

sealed class NavDestination {
  const NavDestination();

  void go(BuildContext context);
}

class NavDestinationHome extends NavDestination {
  const NavDestinationHome();

  @override
  void go(BuildContext context) {
    context.goNamed('home');
  }

  @override
  String toString() {
    return 'NavDestinationHome';
  }
}

class NavDestinationFolder extends NavDestination {
  final String folderId;

  NavDestinationFolder({required this.folderId});

  @override
  void go(BuildContext context) {
    context.goNamed('folder', pathParameters: {'id': folderId});
  }

  @override
  String toString() {
    return 'NavDestinationFolder($folderId)';
  }
}
