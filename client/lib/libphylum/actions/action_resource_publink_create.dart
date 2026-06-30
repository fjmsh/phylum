import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_publink.dart';
import 'package:phylum/libphylum/actions/changes/create_publink_change.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/responses/responses.dart';

import 'action_resource.dart';

class PublinkCreateAction extends ResourceAction
    with JsonApiAction, PublinkAction {
  static const kActionName = 'publinkCreate';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/publinks/create';

  @override
  Map<String, dynamic>? get requestBody => {
    'id': publinkId,
    'resource_path': '$resourceId:',
    if (password.isNotEmpty) 'password': password,
    if (expires != null) 'expires': expires!.toIso8601String(),
    if (accessLimit != 0) 'access_limit': accessLimit,
  };

  @override
  List<LocalChange> get localChanges => [
    CreatePublinkChange(
      objectId: publinkId,
      timestamp: timestamp,
      root: resourceId,
      accessLimit: accessLimit,
      protected: password.isNotEmpty,
      expires: expires,
    ),
  ];

  @override
  String get description => 'Creating Public Share: $publinkId';

  @override
  Map<String, dynamic> get props => {
    'resourceId': resourceId,
    'publinkId': _publinkId,
    'password': password,
    'expires': expires?.millisecondsSinceEpoch,
    'accessLimit': accessLimit,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  String _publinkId;
  @override
  String get publinkId => _publinkId;
  final String password;
  final DateTime? expires;
  final int accessLimit;
  final DateTime timestamp;

  PublinkCreateAction({
    required super.resourceId,
    required this._publinkId,
    required this.password,
    required DateTime? expires,
    required this.accessLimit,
    DateTime? timestamp,
  }) : expires = expires?.toUtc(),
       timestamp = timestamp ?? DateTime.now();

  factory PublinkCreateAction.fromMap(Map<String, dynamic> map) {
    return PublinkCreateAction(
      resourceId: map['resourceId'],
      publinkId: map['publinkId'],
      password: map['password'],
      expires: map['expires'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['expires']),
      accessLimit: map['accessLimit'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, PublinkResponse.fromResponse);
  }

  @override
  bool dependsOn(PhylumAction action) =>
      (action is ResourceAction && action.resourceId == resourceId) ||
      (action is PublinkAction && action.publinkId == publinkId);

  Future<void> updatePublinkId(String publinkId) {
    // return account.actionQueue.updateActions(
    //   (action) => action == this,
    //   (action) =>
    //       (action as ResourcePublinkCreateAction)._publinkId = publinkId,
    // );
    return account.actionQueue.updateActions(
      (PhylumAction action) =>
          action is PublinkAction && action.publinkId == publinkId,
      (action) => (action as PublinkAction).setPublinkId(publinkId),
    );
  }

  @override
  void setPublinkId(String publinkId) {
    _publinkId = publinkId;
  }
}
