import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_mkdir.dart';
import 'package:phylum/libphylum/actions/action_resource_rename.dart';
import 'package:phylum/libphylum/actions/action_resource_upload.dart';

const actionDeserializers = {
  ResourceMkdirAction.actionName: ResourceMkdirAction.fromMap,
  ResourceUploadAction.actionName: ResourceUploadAction.fromMap,
  ResourceRenameAction.actionName: ResourceRenameAction.fromMap,
  ResourceDeleteAction.actionName: ResourceDeleteAction.fromMap,
};
