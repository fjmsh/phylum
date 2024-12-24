import 'package:phylum/libphylum/actions/action_resource_copy.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_mkdir.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/actions/action_resource_share.dart';
import 'package:phylum/libphylum/actions/action_resource_upload.dart';
import 'package:phylum/libphylum/actions/bookmark_add_action.dart';
import 'package:phylum/libphylum/actions/bookmark_remove_action.dart';

const actionDeserializers = {
  BookmarkAddAction.kActionName: BookmarkAddAction.fromMap,
  BookmarkRemoveAction.kActionName: BookmarkRemoveAction.fromMap,
  ResourceCopyAction.kActionName: ResourceCopyAction.fromMap,
  ResourceDeleteAction.kActionName: ResourceDeleteAction.fromMap,
  ResourceMkdirAction.kActionName: ResourceMkdirAction.fromMap,
  ResourceMoveAction.kActionName: ResourceMoveAction.fromMap,
  ResourceShareAction.kActionName: ResourceShareAction.fromMap,
  ResourceUploadAction.kActionName: ResourceUploadAction.fromMap,
};
