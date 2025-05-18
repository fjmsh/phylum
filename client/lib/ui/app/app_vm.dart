import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app.dart';
import 'package:phylum/ui/app/router.dart';

Widget buildApp() => PhylumApp(
      accountManager: createAccountManager(),
      routerDelegate: PhylumRouterDelegate(),
    );
