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
import 'package:phylum/libphylum/config/server_config.dart';
import 'package:phylum/libphylum/requests/bootstrap_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/util/logging/logging.dart';
import 'package:state_notifier/state_notifier.dart';

const _persistKeyApiToken = 'apiToken';
const _persistKeyBootstrapUntil = 'bootstrapUntil';

class PhylumAccount extends Account<PhylumAccount> {
  late final db = AppDatabase(accountId: id);
  final bookmarkRepository = BookmarkRepository();
  final resourceRepository = ResourceRepository();
  final userRepository = UserRepository();
  final trashedResourcRepository = TrashedResourceRepository();
  final publinkRepository = PublinkRepository();
  final resourceVersionRepository = ResourceVersionRepository();

  static String? deviceInfo;

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
  ServerConfig? _initialConfig;

  String? _apiToken;
  set apiKey(String value) {
    _apiToken = value;
    persist(_persistKeyApiToken, value);
    apiClient.setHeader('Authorization', 'Bearer $value');
  }

  late AccountUserNotifier _userNotifier;
  StateNotifier<AccountUser> get userNotifier => _userNotifier;
  AccountUser get user => _userNotifier.user;
  set user(AccountUser value) {
    _userNotifier.user = value;
  }

  int get bootstrapUntil =>
      getPersisted<num>(_persistKeyBootstrapUntil)?.toInt() ?? 0;
  set bootstrapUntil(int value) {
    persist(_persistKeyBootstrapUntil, value);
  }

  late ServerConfigNotifier _configNotifier;
  StateNotifier<ServerConfig> get configNotifier => _configNotifier;
  ServerConfig get config => _configNotifier.config;
  set config(ServerConfig value) {
    _configNotifier.config = value;
  }

  PhylumAccount.create({
    required super.serverUrl,
    required String this._apiToken,
    required AccountUser user,
    required ServerConfig config,
  }) : _initialUser = user,
       _initialConfig = config,
       super.create();

  PhylumAccount.restore({required super.id}) : super.restore() {
    late final void Function() removeListener;
    removeListener = addListener((state) {
      if (state == .ready) {
        apiClient.sendRequest(BootstrapRequest(since: bootstrapUntil));
        Future.microtask(removeListener);
      }
    });
  }

  @override
  Future<void> initialize() async {
    if (_apiToken == null) {
      _apiToken = getPersisted(_persistKeyApiToken);
      if (_apiToken == null) {
        throw 'Could not restore access token';
      }
    } else {
      persist(_persistKeyApiToken, _apiToken);
    }
    apiClient.setHeader('Authorization', 'Bearer $_apiToken');
    apiClient.setHeader('X-Device', deviceInfo);

    if (_initialUser != null) {
      _userNotifier = AccountUserNotifier.fromUser(this, _initialUser!);
    } else {
      _userNotifier = AccountUserNotifier.fromAccount(this);
    }
    if (_initialConfig != null) {
      _configNotifier = ServerConfigNotifier.fromConfig(this, _initialConfig!);
    } else {
      _configNotifier = ServerConfigNotifier.fromAccount(this);
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
          Log.info('Invalid Credentials - Logging out');
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
