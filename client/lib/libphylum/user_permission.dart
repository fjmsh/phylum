typedef UserPermission = String;

const UserPermission userPermissionUsersAll = 'users';
const UserPermission userPermissionUsersList = 'users:list';
const UserPermission userPermissionUsersCreate = 'users:create';
const UserPermission userPermissionUsersCreateInvite = 'users:create:invite';
const UserPermission userPermissionUsersPermissions = 'users:permissions';
const UserPermission userPermissionUsersAuthPasswordUpdate =
    'users:auth:password:update';
const UserPermission userPermissionFilesAll = 'files';
const UserPermission userPermissionFilesRead = 'files:read';
const UserPermission userPermissionFilesWrite = 'files:write';
const UserPermission userPermissionFilesShare = 'files:share';
const UserPermission userPermissionSU = '*';

extension PermissionName on UserPermission {
  String get readableName => switch (this) {
    userPermissionSU => 'SysAdmin',
    userPermissionUsersCreateInvite => 'Invite Users',
    userPermissionFilesAll => 'All Files',
    userPermissionFilesRead => 'Read All Files',
    userPermissionFilesWrite => 'Write All Files',
    userPermissionFilesShare => 'Share All Files',
    userPermissionUsersAll => 'Users',
    userPermissionUsersCreate => 'Create Users',
    userPermissionUsersList => 'List Users',
    userPermissionUsersPermissions => 'Update Permissions',
    userPermissionUsersAuthPasswordUpdate => 'Set Password',
    _ => this,
  };
}
