import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_api_response.dart';

import '../phylum_account.dart';

mixin ResourceCreateAction on ApiAction<PhylumApiResponse, PhylumApiErrorResponse, PhylumAccount> {
  String get resourceId;
}
