import 'package:http/src/streamed_response.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_share.dart';
import 'package:phylum/libphylum/actions/changes/create_user_change.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class UserInviteAction extends PhylumAction with JsonApiAction {
  static const kActionName = 'userInvite';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/users/invite';

  @override
  Map<String, dynamic>? get requestBody => {
        'email': email,
        'name': userName,
      };

  @override
  List<LocalChange> get localChanges => [
        CreateUserChange(localId: localId, email: email, name: userName),
      ];

  @override
  String get description => "Inviting User $email";

  @override
  Map<String, dynamic> get props => {
        'localId': localId,
        'email': email,
        'userName': userName,
      };

  final int localId;
  final String email;
  final String userName;

  UserInviteAction({
    required this.localId,
    required this.email,
    required this.userName,
  });

  static UserInviteAction fromMap(Map<String, dynamic> map) {
    return UserInviteAction(
      localId: map['localId'],
      email: map['email'],
      userName: map['userName'],
    );
  }

  @override
  bool dependsOn(PhylumAction action) => false;

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, UserResponse.fromResponse);
  }

  @override
  bool processResponse(ApiResponse response) {
    if (response is UserResponse) {
      account.actionQueue.updateActions(
        (PhylumAction action) => action is ResourceShareAction && action.userId == localId,
        (action) => (action as ResourceShareAction).setUserId(response.user.id),
      );
    }
    return true;
  }
}
