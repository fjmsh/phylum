import 'package:phylum/libphylum/actions/action_resource_copy.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_mkdir.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/actions/action_resource_publink_create.dart';
import 'package:phylum/libphylum/actions/action_resource_restore.dart';
import 'package:phylum/libphylum/actions/action_resource_share.dart';
import 'package:phylum/libphylum/actions/action_resource_upload.dart';
import 'package:phylum/libphylum/actions/action_resource_bookmark_add.dart';
import 'package:phylum/libphylum/actions/action_resource_bookmark_remove.dart';
import 'package:phylum/libphylum/actions/action_resource_version_delete.dart';
import 'package:phylum/libphylum/actions/action_user_invite.dart';

const actionDeserializers = {
  ResourceBookmarkAddAction.kActionName: ResourceBookmarkAddAction.fromMap,
  ResourceBookmarkRemoveAction.kActionName:
      ResourceBookmarkRemoveAction.fromMap,
  ResourceCopyAction.kActionName: ResourceCopyAction.fromMap,
  ResourceDeleteAction.kActionName: ResourceDeleteAction.fromMap,
  ResourceMkdirAction.kActionName: ResourceMkdirAction.fromMap,
  ResourceMoveAction.kActionName: ResourceMoveAction.fromMap,
  ResourceRestoreAction.kActionName: ResourceRestoreAction.fromMap,
  ResourcePublinkCreateAction.kActionName: ResourcePublinkCreateAction.fromMap,
  ResourceShareAction.kActionName: ResourceShareAction.fromMap,
  ResourceUploadAction.kActionName: ResourceUploadAction.fromMap,
  ResourceVersionDeleteAction.kActionName: ResourceVersionDeleteAction.fromMap,
  UserInviteAction.kActionName: UserInviteAction.fromMap,
};
