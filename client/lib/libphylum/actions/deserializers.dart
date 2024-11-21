import 'package:phylum/libphylum/actions/action_resource_copy.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_mkdir.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/actions/action_resource_upload.dart';
import 'package:phylum/libphylum/actions/bookmark_add_action.dart';
import 'package:phylum/libphylum/actions/bookmark_remove_action.dart';

const actionDeserializers = {
  BookmarkAddAction.actionName: BookmarkAddAction.fromMap,
  BookmarkRemoveAction.actionName: BookmarkRemoveAction.fromMap,
  ResourceDeleteAction.actionName: ResourceDeleteAction.fromMap,
  ResourceMkdirAction.actionName: ResourceMkdirAction.fromMap,
  ResourceMoveAction.actionName: ResourceMoveAction.fromMap,
  ResourceUploadAction.actionName: ResourceUploadAction.fromMap,
  ResourceCopyAction.actionName: ResourceCopyAction.fromMap,
};
