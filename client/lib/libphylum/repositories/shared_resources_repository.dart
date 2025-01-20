import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/parsers/parsers.dart';
import 'package:phylum/libphylum/parsers/shared.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/shared_resources_request.dart';

class SharedResourcesRepository {
  final PhylumAccount account;

  SharedResourcesRepository({required this.account});

  Future<ApiResult> refresh() async {
    return account.apiClient.sendRequest(
      SharedResourcesRequest(),
      (request, response) => parseJsonMapResponse(response, SharedResourcesResponse.fromResponse),
    );
  }
}
