import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:offtheline/offtheline.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:phylum/app.dart';
import 'package:phylum/libphylum/actions/deserializers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/login_page.dart';
import 'package:provider/provider.dart';

const storageDir = String.fromEnvironment("STORAGE_DIR");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDir = (Platform.isLinux)
      ? Directory(path.join((await getApplicationSupportDirectory()).path, storageDir.isNotEmpty ? storageDir : 'data'))
      : await getApplicationDocumentsDirectory();

  OTL.logger = Logger();

  await appDir.create();
  Hive.init(appDir.path);
  Hive.registerAdapter(ApiActionTypeAdapter(actionDeserializers));

  final accountManager = await AccountManager.restore((id) async {
    final account = PhylumAccount(id: id);
    await account.initialized;
    return account;
  });

  runApp(AccountSelector(accountManager: accountManager));
}

class AccountSelector extends StatelessWidget {
  final AccountManager<PhylumAccount> accountManager;
  final Key _loginAppKey = UniqueKey();

  AccountSelector({
    super.key,
    required this.accountManager,
  });

  @override
  Widget build(BuildContext context) => MultiProvider(
          providers: [
            StateNotifierProvider<AccountManager<PhylumAccount>, AccountManagerState<PhylumAccount>>.value(
              value: accountManager,
            ),
          ],
          builder: (context, child) {
            final account = context.select<AccountManagerState<PhylumAccount>, PhylumAccount?>((state) => state.selectedAccount);

            if (account == null) {
              return buildLoginPage(context);
            }
            return PhylumApp(accountId: account.id);
          });

  Widget buildLoginPage(BuildContext context) => MaterialApp(
        key: _loginAppKey,
        title: 'Phylum',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange)),
        darkTheme: ThemeData.dark(),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const LoginPage(),
          );
        },
      );
}
