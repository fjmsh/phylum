import 'package:phylum/libphylum/actions/resource_mkdir_action.dart';
import 'package:phylum/libphylum/actions/resource_rename_action.dart';
import 'package:phylum/libphylum/actions/resource_upload_action.dart';

const actionDeserializers = {
  ResourceMkdirAction.actionName: ResourceMkdirAction.fromMap,
  ResourceUploadAction.actionName: ResourceUploadAction.fromMap,
  ResourceRenameAction.actionName: ResourceRenameAction.fromMap,
};
