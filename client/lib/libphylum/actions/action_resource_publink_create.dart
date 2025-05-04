import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/responses/responses.dart';

import 'action_resource.dart';

class ResourcePublinkCreateAction extends ResourceAction with JsonApiAction {
  static const kActionName = 'publinkCreate';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/publinks/$resourceId/create';

  @override
  Map<String, dynamic>? get requestBody => {
        'name': publinkName,
        if (password.isNotEmpty) 'password': password,
        if (expires != null) 'expires': expires!.toIso8601String(),
        if (accessLimit != 0) 'access_limit': accessLimit,
      };

  @override
  ResponseParser get parseResponse => (_, response) => parseJsonMapResponse(response, EmptyResponse.fromResponse);

  @override
  List<LocalChange> get localChanges => [];

  @override
  String get description => 'Creating Public Share: $publinkName';

  @override
  Map<String, dynamic> get props => {
        'resourceId': resourceId,
        'publinkName': _publinkName,
        'password': password,
        'expires': expires?.millisecondsSinceEpoch,
        'accessLimit': accessLimit,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  String _publinkName;
  String get publinkName => _publinkName;
  final String password;
  final DateTime? expires;
  final int accessLimit;
  final DateTime timestamp;

  ResourcePublinkCreateAction({
    required super.resourceId,
    required String publinkName,
    required this.password,
    required DateTime? expires,
    required this.accessLimit,
    DateTime? timestamp,
  })  : _publinkName = publinkName,
        expires = expires?.toUtc(),
        timestamp = timestamp ?? DateTime.now();

  factory ResourcePublinkCreateAction.fromMap(Map<String, dynamic> map) {
    return ResourcePublinkCreateAction(
      resourceId: map['resourceId'],
      publinkName: map['publinkName'],
      password: map['password'],
      expires: map['expires'] == null ? null : DateTime.fromMillisecondsSinceEpoch(map['expires']),
      accessLimit: map['accessLimit'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  bool dependsOn(PhylumAction action) =>
      action is ResourceAction &&
      (action is ResourceCreateAction || action is ResourcePublinkCreateAction) &&
      action.resourceId == resourceId;

  Future<void> updatePublinkName(String publinkName) {
    return account.actionQueue.updateActions(
      (action) => action == this,
      (action) => (action as ResourcePublinkCreateAction)._publinkName = publinkName,
    );
  }
}
