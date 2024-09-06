import 'dart:convert';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_datastore.dart';

const _persistKeyAccessToken = 'accessToken';
const _persistKeyUserEmail = 'userEmail';
const _persistKeyUserName = 'userName';
const _persistKeyUserHome = 'userHome';

class PhylumAccount extends Account<Map<String, dynamic>> {
  final PhylumDatastore datastore = PhylumDatastore();

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

  PhylumAccount({super.id}) : super(api: ApiClient(transformResponse: (response) => jsonDecode(response) as Map<String, dynamic>?));

  @override
  Future<String?> initialize() async {
    await super.initialize();
    // Set Authorization header
    _accessToken = accessToken;

    return await registerListener(datastore);
  }

  static Future<PhylumAccount> createFromLoginResponse(Map<String, dynamic> response) async {
    final account = PhylumAccount();
    await account.initialized;
    account._accessToken = response['access_token'];

    final userMap = response['user'];
    account.userEmail = userMap['email'];
    account.userName = userMap['name'];
    account.userHome = userMap['home'];

    return account;
  }
}
