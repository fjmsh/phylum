import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/resource_mkdir_action.dart';
import 'package:phylum/libphylum/phylum_account.dart';

const actionDeserializers = <String, ApiActionDeserializer<PhylumAccount>>{
  ResourceMkdirAction.actionName: ResourceMkdirAction.fromMap,
};
