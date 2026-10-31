import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

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
const _persistKeyDbPassphrase = 'dbPassphrase';
const _persistKeyBootstrapUntil = 'bootstrapUntil';

class PhylumAccount extends Account<PhylumAccount> {
  late final AppDatabase db;
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
    required String apiToken,
    required AccountUser user,
    required ServerConfig config,
  }) : super.create(
         params: CreateParams(apiToken: apiToken, user: user, config: config),
       );

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
  Future<void> initialize(covariant CreateParams? createParams) async {
    late final String apiToken;
    if (createParams == null) {
      db = AppDatabase(
        accountId: id,
        passphrase: getPersisted<String>(_persistKeyDbPassphrase)!,
      );
      apiToken = getPersisted(_persistKeyApiToken);
      _userNotifier = AccountUserNotifier.fromAccount(this);
      _configNotifier = ServerConfigNotifier.fromAccount(this);
    } else {
      final passphrase = base64.encode(Random.secure().nextBytes(32));
      persist(_persistKeyDbPassphrase, passphrase);
      persist(_persistKeyApiToken, createParams.apiToken);

      db = AppDatabase(accountId: id, passphrase: passphrase);
      apiToken = createParams.apiToken;
      _userNotifier = AccountUserNotifier.fromUser(this, createParams.user);
      _configNotifier = ServerConfigNotifier.fromConfig(
        this,
        createParams.config,
      );
    }

    apiClient.setHeader('Authorization', 'Bearer $apiToken');
    apiClient.setHeader('X-Device', deviceInfo);

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

final class CreateParams {
  final String apiToken;
  final AccountUser user;
  final ServerConfig config;

  CreateParams({
    required this.apiToken,
    required this.user,
    required this.config,
  });
}

extension on Random {
  Uint8List nextBytes(int bytes) {
    final buffer = Uint8List(bytes);
    for (var i = 0; i < bytes; i++) {
      buffer[i] = nextInt(0xFF + 1);
    }
    return buffer;
  }
}
