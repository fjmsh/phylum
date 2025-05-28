import 'dart:async';
import 'dart:convert';

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

const _persistKeyAccessToken = 'accessToken';
const _persistKeyUser = 'user';
const _persistKeyBootstrapUntil = 'bootstrapUntil';

AccountManager<PhylumAccount> createAccountManager(bool autoInitialize) => AccountManager((id) async {
      final account = PhylumAccount.restore(id: id);
      final err = await account.initialized;
      if (err != null) {
        throw err;
      }
      return account;
    }, autoInitialize: autoInitialize);

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

  String? _initialAccessToken;
  LoggedInUser? _initialLoggedInUser;

  String? get accessToken => getPersisted(_persistKeyAccessToken);
  set _accessToken(String? value) {
    if (value != accessToken) {
      persist(_persistKeyAccessToken, value);
    }
    apiClient.setHeader('Authorization', 'bearer $value');
  }

  late LoggedInUser _loggedInUser;
  set loggedInUser(LoggedInUser value) {
    if (_loggedInUser != value) {
      _loggedInUser = value;
      persist(_persistKeyUser, jsonEncode(value.toJson()));
    }
  }

  int get userId => _loggedInUser.id;
  String get userEmail => _loggedInUser.email;
  String get userName => _loggedInUser.name;
  String get userHome => _loggedInUser.home;
  bool hasPermission(UserPermission p) => _loggedInUser.permissions & p != 0;

  int get bootstrapUntil => getPersisted<num>(_persistKeyBootstrapUntil)?.toInt() ?? 0;
  set bootstrapUntil(int value) {
    persist(_persistKeyBootstrapUntil, value);
  }

  PhylumAccount.create({required super.serverUri, required String accessToken, required LoggedInUser user})
      : _initialAccessToken = accessToken,
        _initialLoggedInUser = user,
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
    if (_initialLoggedInUser != null) {
      _loggedInUser = _initialLoggedInUser!;
      persist(_persistKeyUser, jsonEncode(_initialLoggedInUser!.toJson()));
    } else {
      _loggedInUser = LoggedInUser.fromJson(jsonDecode(getPersisted(_persistKeyUser)));
    }
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
}
