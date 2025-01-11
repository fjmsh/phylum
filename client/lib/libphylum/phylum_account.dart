import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/repositories/my_lists_repository.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/libphylum/repositories/user_repository.dart';
import 'package:phylum/libphylum/server_data_tracker.dart';
import 'package:phylum/util/logging.dart';

const _persistKeyAccessToken = 'accessToken';
const _persistKeyUserEmail = 'userEmail';
const _persistKeyUserName = 'userName';
const _persistKeyUserHome = 'userHome';

class PhylumAccount extends Account<PhylumAccount> {
  late final db = AppDatabase(accountId: id);
  late final resourceRepository = ResourceRepository(account: this);
  late final userRepository = UserRepository(account: this);
  late final myListsRepository = MyListsRepository(account: this);
  late final serverResourceTracker = ServerResourceStateTracker(account: this);

  final _dispatcher = SimulatedBadNetworkDispatcher.good(dropRate: 0);
  // final _dispatcher = HttpClientDispatcher();
  @override
  Dispatcher get dispatcher => _dispatcher;

  String? _initialAccessToken;
  String? get accessToken => getPersisted(_persistKeyAccessToken);
  set _accessToken(String? value) {
    if (value != accessToken) {
      persist(_persistKeyAccessToken, value);
    }
    apiClient.setHeader('Authorization', 'bearer $value');
  }

  String get userEmail => getPersisted(_persistKeyUserEmail);
  set userEmail(String value) {
    persist(_persistKeyUserEmail, value);
  }

  String get userName => getPersisted(_persistKeyUserName);
  set userName(String value) {
    persist(_persistKeyUserName, value);
  }

  String get userHome => getPersisted(_persistKeyUserHome);
  set userHome(String value) {
    persist(_persistKeyUserHome, value);
  }

  PhylumAccount.create({required super.serverUri, required String accessToken})
      : _initialAccessToken = accessToken,
        super.create(transformResponse: transformApiResponse);

  PhylumAccount.restore({required super.id}) : super.restore(transformResponse: transformApiResponse);

  @override
  Future<void> initialize() async {
    await super.initialize();
    // Set Authorization header
    _accessToken = _initialAccessToken ?? accessToken;

    // Open the database to see if data was cleared
    await db.bookmarks.count().get();
    await serverResourceTracker.initialize();
    await userRepository.initialize(db.cleared);
    await myListsRepository.initialize(db.cleared);

    void Function()? l;
    l = apiClient.addResponseListener((request, errorResponse) {
      if (errorResponse is PhylumApiErrorResponse) {
        if (errorResponse.code == "credentials_invalid") {
          logger.i('Invalid Credentials - Logging out');
          logOut();
          l?.call();
        }
      }
    });
  }

  @override
  Future<void> transaction(Future<void> Function() fn, {bool retainServerData = false, bool clearUntouched = true}) {
    return db.transaction(fn, interceptor: retainServerData ? serverResourceTracker.newInterceptor(clearUntouched) : null);
  }

  @override
  Future<void> cleanup() async {
    await super.cleanup();
    await db.dropDatabase();
  }

  static Future<PhylumAccount> createFromLoginResponse(Uri serverUri, Map<String, dynamic> response) async {
    final account = PhylumAccount.create(serverUri: serverUri, accessToken: response['access_token']);
    await account.initialized;

    final userMap = response['user'];
    account.userEmail = userMap['username'];
    account.userName = userMap['display'];
    account.userHome = userMap['home'];

    return account;
  }
}
