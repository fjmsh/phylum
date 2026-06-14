typedef UserPermission = String;

const UserPermission userPermissionInvite = 'invite';
const UserPermission userPermissionUsersAll = 'users';
const UserPermission userPermissionUsersList = 'users:list';
const UserPermission userPermissionUsersAdd = 'users:add';
const UserPermission userPermissionUsersGrant = 'users:grant';
const UserPermission userPermissionFilesAll = 'files';
const UserPermission userPermissionFilesRead = 'files:read';
const UserPermission userPermissionFilesWrite = 'files:write';
const UserPermission userPermissionFilesShare = 'files:share';
const UserPermission userPermissionSU = '*';

extension PermissionName on UserPermission {
  String get readableName => switch (this) {
        '*' => 'SysAdmin',
        _ => this,
      };
}
