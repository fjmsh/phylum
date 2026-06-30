import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/responses/responses.dart';

abstract class ResourceAction extends PhylumAction {
  String _resourceId;
  String get resourceId => _resourceId;

  ResourceAction({required this._resourceId});

  void setResourceId(String resourceId) {
    _resourceId = resourceId;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, ResourceResponse.fromResponse);
  }
}
