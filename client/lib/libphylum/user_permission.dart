typedef UserPermission = String;

const UserPermission userPermissionSU = '*';
const UserPermission userPermissionFilesAll = 'files';
const UserPermission userPermissionFilesRead = 'files:read';
const UserPermission userPermissionFilesWrite = 'files:write';
const UserPermission userPermissionFilesShare = 'files:share';
const UserPermission userPermissionConfigAuthAll = 'config:auth';
const UserPermission userPermissionConfigAuthRead = 'config:auth:read';
const UserPermission userPermissionConfigAuthUpdate = 'config:auth:update';
const UserPermission userPermissionConfigMailAll = 'config:mail';
const UserPermission userPermissionConfigMailRead = 'config:mail:read';
const UserPermission userPermissionConfigMailUpdate = 'config:mail:update';
const UserPermission userPermissionUsersAll = 'users';
const UserPermission userPermissionUsersList = 'users:list';
const UserPermission userPermissionUsersCreate = 'users:create';
const UserPermission userPermissionUsersCreateInvite = 'users:create:invite';
const UserPermission userPermissionUsersPermissions = 'users:permissions';
const UserPermission userPermissionUsersAuthPasswordUpdate =
    'users:auth:password:update';

const List<UserPermission> userPermissionList = [
  userPermissionSU,
  userPermissionUsersAll,
  userPermissionUsersList,
  userPermissionUsersCreate,
  userPermissionUsersCreateInvite,
  userPermissionUsersPermissions,
  userPermissionUsersAuthPasswordUpdate,
  userPermissionConfigMailAll,
  userPermissionConfigAuthAll,
  userPermissionFilesAll,
  userPermissionFilesRead,
  userPermissionFilesWrite,
  userPermissionFilesShare,
];

extension PermissionName on UserPermission {
  String get readableName => switch (this) {
    userPermissionSU => 'SysAdmin',
    userPermissionConfigAuthAll => 'Configure Auth',
    userPermissionConfigAuthRead => 'Read Auth Configuration',
    userPermissionConfigAuthUpdate => 'Update Auth Configuration',
    userPermissionConfigMailAll => 'Configure Email',
    userPermissionConfigMailRead => 'Read Email Configuration',
    userPermissionConfigMailUpdate => 'Update Email Configuration',
    userPermissionFilesAll => 'Manage All Files',
    userPermissionFilesRead => 'Read All Files',
    userPermissionFilesWrite => 'Write All Files',
    userPermissionFilesShare => 'Share All Files',
    userPermissionUsersAll => 'Manage Users',
    userPermissionUsersList => 'List Users',
    userPermissionUsersCreate => 'Create Users',
    userPermissionUsersCreateInvite => 'Invite Users',
    userPermissionUsersPermissions => 'Update User Permissions',
    userPermissionUsersAuthPasswordUpdate => 'Set User Password',
    _ => this,
  };
}
