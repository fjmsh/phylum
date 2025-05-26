import 'package:offtheline/offtheline.dart';
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
        'display_name': displayName,
      };

  @override
  List<LocalChange> get localChanges => [];

  @override
  String get description => "Inviting User $email";

  @override
  Map<String, dynamic> get props => {
        'email': email,
        'displayName': displayName,
      };

  final String email;
  final String displayName;

  UserInviteAction({
    required this.email,
    required this.displayName,
  });

  static UserInviteAction fromMap(Map<String, dynamic> map) {
    return UserInviteAction(
      email: map['email'],
      displayName: map['displayName'],
    );
  }

  @override
  bool dependsOn(PhylumAction action) => false;

  @override
  ResponseParser get parseResponse => (_, response) => parseJsonMapResponse(response, UserResponse.fromResponse);
}
