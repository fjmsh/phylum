import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_publink.dart';
import 'package:phylum/libphylum/actions/changes/delete_publink_change.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class PublinkDeleteAction extends PhylumAction
    with JsonApiAction, PublinkAction {
  static const kActionName = 'publinkDelete';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/publinks/delete';

  @override
  Map<String, dynamic>? get requestBody => {'id': publinkId};

  @override
  List<LocalChange> get localChanges => [
    DeletePublinkChange(objectId: publinkId),
  ];

  @override
  String get description => 'Deleting Public Share: $publinkId';

  @override
  Map<String, dynamic> get props => {'publinkId': publinkId};

  String _publinkId;
  @override
  String get publinkId => _publinkId;

  PublinkDeleteAction({required this._publinkId});

  factory PublinkDeleteAction.fromMap(Map<String, dynamic> map) {
    return PublinkDeleteAction(publinkId: map['publinkId']);
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, EmptyResponse.fromResponse);
  }

  @override
  bool dependsOn(PhylumAction action) =>
      action is PublinkAction && action.publinkId == publinkId;

  @override
  void setPublinkId(String publinkId) {
    _publinkId = publinkId;
  }
}
