import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/repositories/bookmark_repository.dart';
import 'package:phylum/libphylum/repositories/shared_resources_repository.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/libphylum/repositories/trash_repository.dart';
import 'package:phylum/libphylum/repositories/user_repository.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/util/logging.dart';

const _persistKeyAccessToken = 'accessToken';
const _persistKeyUserId = 'userId';
const _persistKeyUserEmail = 'userEmail';
const _persistKeyUserDisplayName = 'userDisplayName';
const _persistKeyUserHome = 'userHome';
const _persistKeyUserPermissions = 'userPermissions';

AccountManager<PhylumAccount> createAccountManager() => AccountManager((id) async {
      final account = PhylumAccount.restore(id: id);
      final err = await account.initialized;
      if (err != null) {
        throw err;
      }
      return account;
    });

class PhylumAccount extends Account<PhylumAccount> {
  late final db = AppDatabase(accountId: id);
  final resourceRepository = ResourceRepository();
  final bookmarkRepository = BookmarkRepository();
  final trashedResourcRepository = TrashedResourceRepository();
  late final userRepository = UserRepository(account: this);
  late final sharedResourcesRepository = SharedResourcesRepository(account: this);

  @override
  Map<Type, Repository<PhylumAccount, dynamic>> get repositories => {
        Resource: resourceRepository,
        Bookmark: bookmarkRepository,
        TrashedResource: trashedResourcRepository,
      };

  @override
  Dispatcher dispatcher = HttpClientDispatcher();

  String? _initialAccessToken;
  String? get accessToken => getPersisted(_persistKeyAccessToken);
  set _accessToken(String? value) {
    if (value != accessToken) {
      persist(_persistKeyAccessToken, value);
    }
    apiClient.setHeader('Authorization', 'bearer $value');
  }

  int get userId => getPersisted(_persistKeyUserId);
  set userId(int value) {
    persist(_persistKeyUserId, value);
  }

  String get userEmail => getPersisted(_persistKeyUserEmail);
  set userEmail(String value) {
    persist(_persistKeyUserEmail, value);
  }

  String get userDisplayName => getPersisted(_persistKeyUserDisplayName);
  set userDisplayName(String value) {
    persist(_persistKeyUserDisplayName, value);
  }

  String get userHome => getPersisted(_persistKeyUserHome);
  set userHome(String value) {
    persist(_persistKeyUserHome, value);
  }

  int get userPermissions => getPersisted(_persistKeyUserPermissions);
  set userPermissions(int value) {
    persist(_persistKeyUserPermissions, value);
  }

  PhylumAccount.create({required super.serverUri, required String accessToken})
      : _initialAccessToken = accessToken,
        super.create();

  PhylumAccount.restore({required super.id}) : super.restore();

  @override
  Future<void> initialize() async {
    await super.initialize();
    // Set Authorization header
    _accessToken = _initialAccessToken ?? accessToken;

    final dispatcherOverride = const String.fromEnvironment('dispatcher');
    dispatcher = switch (dispatcherOverride) {
      'good' => SimulatedBadNetworkDispatcher.good(),
      'okay' => SimulatedBadNetworkDispatcher.okay(),
      'bad' => SimulatedBadNetworkDispatcher.bad(),
      _ => HttpClientDispatcher(),
    };

    await userRepository.initialize();
    await bookmarkRepository.initialize();

    late final void Function() l;
    l = apiClient.addListener((request, errorResponse) {
      if (errorResponse is PhylumApiErrorResponse) {
        if (errorResponse.code == "credentials_invalid") {
          logger.i('Invalid Credentials - Logging out');
          close(clearData: true);
          l.call();
        }
      }
    });
  }

  @override
  Future<void> transaction(Future<void> Function() fn) => db.transaction(fn);

  @override
  Future<void> cleanup(bool clearData) async {
    await super.cleanup(clearData);
    if (clearData) {
      await db.dropDatabase();
    }
  }

  static Future<PhylumAccount> createFromLoginResponse(
    Uri serverUri,
    Map<String, dynamic> response,
  ) async {
    final account = PhylumAccount.create(serverUri: serverUri, accessToken: response['access_token']);
    await account.initialized;

    final userMap = response['user'];
    account.userEmail = userMap['email'];
    account.userDisplayName = userMap['display_name'];
    account.userId = userMap['id'];
    account.userHome = userMap['home'];
    account.userPermissions = userMap['permissions'];

    return account;
  }
}
