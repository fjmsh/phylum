import 'dart:convert';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_datastore.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';

const _persistKeyAccessToken = 'accessToken';
const _persistKeyUserEmail = 'userEmail';
const _persistKeyUserName = 'userName';
const _persistKeyUserHome = 'userHome';

typedef PhylumApiResponse = Map<String, dynamic>;

class PhylumApiErrorResponse {
  final String code;
  final String message;

  PhylumApiErrorResponse._({required this.code, required this.message});

  factory PhylumApiErrorResponse.fromResponseString(String response) {
    final map = (jsonDecode(response) as Map<String, dynamic>?) ?? const {};
    return PhylumApiErrorResponse._(code: map['code'] ?? 'server_error', message: map['msg'] ?? 'Server Error');
  }
}

Map<String, dynamic> _tansformResponse(String response) => (jsonDecode(response) as Map<String, dynamic>?) ?? const {};

class PhylumAccount extends Account<PhylumApiResponse, PhylumApiErrorResponse, PhylumAccount> {
  late final db = AppDatabase(id: id);
  late final resourceRepository = ResourceRepository(account: this);
  final datastore = PhylumDatastore();
  final actionQueue = ApiActionQueue<PhylumApiResponse, PhylumApiErrorResponse, PhylumAccount>();

  String? get accessToken => getPersisted(_persistKeyAccessToken);
  set _accessToken(String? value) {
    if (value != accessToken) {
      persist(_persistKeyAccessToken, value);
    }
    api.setHeader('Authorization', 'bearer $value');
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

  PhylumAccount.create({required super.serverUri})
      : super.create(
          transformResponse: _tansformResponse,
          transformErrorResponse: PhylumApiErrorResponse.fromResponseString,
        );
  PhylumAccount.restore({required super.id})
      : super.restore(
          transformResponse: _tansformResponse,
          transformErrorResponse: PhylumApiErrorResponse.fromResponseString,
        );

  @override
  Future<void> initialize() async {
    await super.initialize();
    // Set Authorization header
    _accessToken = accessToken;

    await registerListener(datastore);
    await registerListener(actionQueue);
  }

  @override
  Future<void> clearData() async {
    await super.clearData();
    await db.dropDatabase();
  }

  Future<void> addAction(ApiAction<PhylumAccount> action) async {
    return actionQueue.addAction(action);
  }

  static Future<PhylumAccount> createFromLoginResponse(Uri serverUri, Map<String, dynamic> response) async {
    final account = PhylumAccount.create(serverUri: serverUri);
    await account.initialized;
    account._accessToken = response['access_token'];

    final userMap = response['user'];
    account.userEmail = userMap['username'];
    account.userName = userMap['name'];
    account.userHome = userMap['home'];

    return account;
  }
}
