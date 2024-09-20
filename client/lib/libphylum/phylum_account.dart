import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_response.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/util/logging.dart';

const _persistKeyAccessToken = 'accessToken';
const _persistKeyUserEmail = 'userEmail';
const _persistKeyUserName = 'userName';
const _persistKeyUserHome = 'userHome';

class PhylumAccount extends Account<PhylumApiResponse, PhylumApiErrorResponse, PhylumAccount> {
  late final db = AppDatabase(id: id);
  late final resourceRepository = ResourceRepository(account: this);

  late final _dispatcher = HttpClientDispatcher();
  @override
  Dispatcher get dispatcher => _dispatcher;

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

  PhylumAccount.create({required super.serverUri}) : super.create(transformResponse: transformApiResponse);

  PhylumAccount.restore({required super.id}) : super.restore(transformResponse: transformApiResponse);

  @override
  Future<void> initialize() async {
    await super.initialize();
    // Set Authorization header
    _accessToken = accessToken;

    void Function()? l;
    l = apiClient.addResponseListener((request, errorResponse) {
      if (errorResponse is ApiErrorResponse<PhylumApiResponse, PhylumApiErrorResponse>) {
        if (errorResponse.err.code == "credentials_invalid") {
          logger.i('Invalid Credentials - Logging out');
          logOut();
          l?.call();
        }
      }
    });
  }

  @override
  Future<void> clearData() async {
    await super.clearData();
    await db.dropDatabase();
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
