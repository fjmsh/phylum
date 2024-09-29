import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_mkdir.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/actions/action_resource_upload.dart';

const actionDeserializers = {
  ResourceDeleteAction.actionName: ResourceDeleteAction.fromMap,
  ResourceMkdirAction.actionName: ResourceMkdirAction.fromMap,
  ResourceMoveAction.actionName: ResourceMoveAction.fromMap,
  ResourceUploadAction.actionName: ResourceUploadAction.fromMap,
};
