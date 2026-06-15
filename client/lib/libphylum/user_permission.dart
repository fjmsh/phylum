typedef UserPermission = String;

const UserPermission userPermissionInvite = 'invite';
const UserPermission userPermissionUsersAll = 'users';
const UserPermission userPermissionUsersList = 'users:list';
const UserPermission userPermissionUsersCreate = 'users:create';
const UserPermission userPermissionUsersGrant = 'users:grant';
const UserPermission userPermissionFilesAll = 'files';
const UserPermission userPermissionFilesRead = 'files:read';
const UserPermission userPermissionFilesWrite = 'files:write';
const UserPermission userPermissionFilesShare = 'files:share';
const UserPermission userPermissionSU = '*';

extension PermissionName on UserPermission {
  String get readableName => switch (this) {
        userPermissionSU => 'SysAdmin',
        userPermissionInvite => 'Invite Users',
        userPermissionFilesAll => 'All Files',
        userPermissionFilesRead => 'Read All Files',
        userPermissionFilesWrite => 'Write All Files',
        userPermissionFilesShare => 'Share All Files',
        userPermissionUsersAll => 'Users',
        userPermissionUsersCreate => 'Create Users',
        userPermissionUsersList => 'List Users',
        userPermissionUsersGrant => 'Grant Permissions',
        _ => this,
      };
}
