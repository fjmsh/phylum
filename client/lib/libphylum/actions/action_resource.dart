import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/responses/responses.dart';

abstract class ResourceAction extends PhylumAction {
  String _resourceId;
  String get resourceId => _resourceId;

  @override
  ResponseParser get parseResponse => (_, response) =>
      parseJsonMapResponse(response, (response) => ResourceResponse.fromResponse(response, username: ''));

  ResourceAction({required String resourceId}) : _resourceId = resourceId;

  void setResourceId(String resourceId) {
    _resourceId = resourceId;
  }
}
