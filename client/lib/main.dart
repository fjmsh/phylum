import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:offtheline/offtheline.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:phylum/app.dart';
import 'package:phylum/integrations/directories.dart';
import 'package:phylum/libphylum/actions/deserializers.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/login_page.dart';
import 'package:phylum/util/logging.dart';
import 'package:provider/provider.dart';

const storageDir = String.fromEnvironment("STORAGE_DIR");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PhylumDirectories.instance.initialize();
  logger = Logger(level: Level.info, printer: PrettyPrinter(methodCount: 0, noBoxingByDefault: true));
  OTL.logger = logger;
  GoRouter.optionURLReflectsImperativeAPIs = true;
  // We use multiple distinct databases for different accounts, so this is expected behavior
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  if (kIsWeb) {
    Hive.init(null, backendPreference: HiveStorageBackendPreference.webWorker);
  } else {
    final appDir = (Platform.isLinux)
        ? Directory(path.join((await getApplicationSupportDirectory()).path, storageDir.isNotEmpty ? storageDir : 'data'))
        : await getApplicationDocumentsDirectory();
    AppDatabase.storageDir = appDir;
    AppDatabase.tmpDir = await getTemporaryDirectory();

    await appDir.create();
    Hive.init(appDir.path);
  }
  Hive.registerAdapter(ApiActionTypeAdapter(actionDeserializers));

  final accountManager = await AccountManager.restore((id) async {
    final account = PhylumAccount.restore(id: id);
    final err = await account.initialized;
    if (err != null) {
      logger.e("Unable to restore account: $err");
      return null;
    }
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
            return PhylumApp.create(account);
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
