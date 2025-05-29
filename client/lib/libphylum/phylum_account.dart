import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/logged_in_user.dart';
import 'package:phylum/libphylum/repositories/bookmark_repository.dart';
import 'package:phylum/libphylum/repositories/publink_repository.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/libphylum/repositories/trash_repository.dart';
import 'package:phylum/libphylum/repositories/user_repository.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/util/logging.dart';
import 'package:state_notifier/state_notifier.dart';

const _persistKeyAccessToken = 'accessToken';
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

  @override
  Map<Type, Repository<PhylumAccount, dynamic>> get repositories => {
        Bookmark: bookmarkRepository,
        Resource: resourceRepository,
        Publink: publinkRepository,
        TrashedResource: trashedResourcRepository,
        User: userRepository,
      };

  @override
  Dispatcher dispatcher = HttpClientDispatcher();

  LoggedInUser? _initialLoggedInUser;

  String? _accessToken;
  set accessToken(String value) {
    _accessToken = value;
    persist(_persistKeyAccessToken, value);
    apiClient.setHeader('Authorization', 'bearer $value');
  }

  late LoggedInUserNotifier _userNotifier;
  StateNotifier<LoggedInUser> get userNotifier => _userNotifier;
  LoggedInUser get user => _userNotifier.user;
  set user(LoggedInUser value) {
    _userNotifier.user = value;
  }

  int get bootstrapUntil => getPersisted<num>(_persistKeyBootstrapUntil)?.toInt() ?? 0;
  set bootstrapUntil(int value) {
    persist(_persistKeyBootstrapUntil, value);
  }

  PhylumAccount._create({required super.serverUrl, required String accessToken, required LoggedInUser user})
      : _accessToken = accessToken,
        _initialLoggedInUser = user,
        super.create();

  PhylumAccount.restore({required super.id}) : super.restore();

  static Future<PhylumAccount> create(
      {required Uri serverUrl, required String accessToken, required LoggedInUser user}) async {
    final account = PhylumAccount._create(serverUrl: serverUrl, accessToken: accessToken, user: user);
    await account.setup();
    return account;
  }

  @override
  Future<void> initialize() async {
    await super.initialize();
    if (_accessToken == null) {
      _accessToken = getPersisted(_persistKeyAccessToken);
      if (_accessToken == null) {
        throw 'Could not restore access token';
      }
    } else {
      persist(_persistKeyAccessToken, _accessToken);
    }
    apiClient.setHeader('Authorization', 'bearer $_accessToken');

    if (_initialLoggedInUser != null) {
      _userNotifier = LoggedInUserNotifier.fromUser(this, _initialLoggedInUser!);
    } else {
      _userNotifier = LoggedInUserNotifier.fromAccount(this);
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
