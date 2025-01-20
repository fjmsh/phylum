import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';

typedef PhylumAction = OfflineAction<PhylumAccount>;
typedef PhylumActionQueue = ApiActionQueue<PhylumAccount>;
typedef PhylumActionQueueState = ApiActionQueueState<PhylumAccount>;

abstract class PhylumApiSuccessResponse extends ApiResponse<PhylumAccount> {
  @override
  bool get success => true;

  @override
  String get description => 'Success';

  const PhylumApiSuccessResponse();
}

class PhylumApiErrorResponse extends ApiResponse<PhylumAccount> {
  final int httpStatusCode;
  final String code;
  final String message;

  @override
  String get description => 'Api Error: $message';

  @override
  bool get success => false;

  @override
  Iterable<(Type, String)> get updatedObjects => const [];

  @override
  Future<void> process(PhylumAccount account) => Future.value();

  PhylumApiErrorResponse({required this.httpStatusCode, required this.code, required this.message});
}
