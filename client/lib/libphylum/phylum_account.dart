import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/account_user.dart';
import 'package:phylum/libphylum/repositories/bookmark_repository.dart';
import 'package:phylum/libphylum/repositories/publink_repository.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/libphylum/repositories/resource_version_repository.dart';
import 'package:phylum/libphylum/repositories/trash_repository.dart';
import 'package:phylum/libphylum/repositories/user_repository.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/util/logging.dart';
import 'package:state_notifier/state_notifier.dart';

const _persistKeyApiKey = 'apiKey';
const _persistKeyBootstrapUntil = 'bootstrapUntil';

AccountManager<PhylumAccount> createAccountManager(bool autoInitialize) => AccountManager(
      (id) => PhylumAccount.restore(id: id),
      autoInitialize: autoInitialize,
    );

class PhylumAccount extends Account<PhylumAccount> {
  late final db = AppDatabase(accountId: id);
  final bookmarkRepository = BookmarkRepository();
  final resourceRepository = ResourceRepository();
  final userRepository = UserRepository();
  final trashedResourcRepository = TrashedResourceRepository();
  final publinkRepository = PublinkRepository();
  final resourceVersionRepository = ResourceVersionRepository();

  @override
  Map<Type, Repository<PhylumAccount, dynamic>> get repositories => {
        Bookmark: bookmarkRepository,
        Publink: publinkRepository,
        Resource: resourceRepository,
        ResourceVersion: resourceVersionRepository,
        TrashedResource: trashedResourcRepository,
        User: userRepository,
      };

  @override
  Dispatcher dispatcher = HttpClientDispatcher();

  AccountUser? _initialUser;

  String? _apiKey;
  set apiKey(String value) {
    _apiKey = value;
    persist(_persistKeyApiKey, value);
    apiClient.setHeader('Authorization', 'api-key $value');
  }

  late AccountUserNotifier _userNotifier;
  StateNotifier<AccountUser> get userNotifier => _userNotifier;
  AccountUser get user => _userNotifier.user;
  set user(AccountUser value) {
    _userNotifier.user = value;
  }

  int get bootstrapUntil => getPersisted<num>(_persistKeyBootstrapUntil)?.toInt() ?? 0;
  set bootstrapUntil(int value) {
    persist(_persistKeyBootstrapUntil, value);
  }

  PhylumAccount._create({required super.serverUrl, required String apiKey, required AccountUser user})
      : _apiKey = apiKey,
        _initialUser = user,
        super.create();

  PhylumAccount.restore({required super.id}) : super.restore();

  static Future<PhylumAccount> create(
      {required Uri serverUrl, required String apiKey, required AccountUser user}) async {
    final account = PhylumAccount._create(serverUrl: serverUrl, apiKey: apiKey, user: user);
    await account.setup();
    return account;
  }

  @override
  Future<void> initialize() async {
    await super.initialize();
    if (_apiKey == null) {
      _apiKey = getPersisted(_persistKeyApiKey);
      if (_apiKey == null) {
        throw 'Could not restore access token';
      }
    } else {
      persist(_persistKeyApiKey, _apiKey);
    }
    apiClient.setHeader('Authorization', 'api-key $_apiKey');

    if (_initialUser != null) {
      _userNotifier = AccountUserNotifier.fromUser(this, _initialUser!);
    } else {
      _userNotifier = AccountUserNotifier.fromAccount(this);
    }

    final dispatcherOverride = const String.fromEnvironment('dispatcher');
    dispatcher = switch (dispatcherOverride) {
      'good' => SimulatedBadNetworkDispatcher.good(),
      'okay' => SimulatedBadNetworkDispatcher.okay(),
      'bad' => SimulatedBadNetworkDispatcher.bad(),
      _ => HttpClientDispatcher(),
    };

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
  Future<void> closePersistence(bool clearData) async {
    await super.closePersistence(clearData);
    if (clearData) {
      await db.dropDatabase();
    }
  }
}
