import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';

typedef PhylumAction = OfflineAction<PhylumAccount>;
typedef PhylumActionQueue = ApiActionQueue<PhylumAccount>;
typedef PhylumActionQueueState = ApiActionQueueState<PhylumAccount>;
