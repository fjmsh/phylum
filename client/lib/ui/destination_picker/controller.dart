import 'package:phylum/libphylum/db/db.dart';
import 'package:state_notifier/state_notifier.dart';

class DestinationPickerState {
  final String initialFolder;
  final Resource folder;

  DestinationPickerState({required this.initialFolder, required this.folder});
}

class DestinationPickerController extends StateNotifier<DestinationPickerState> {
  DestinationPickerController(Resource folder) : super(DestinationPickerState(initialFolder: folder.id, folder: folder));

  void updateFolder(Resource folder) {
    state = DestinationPickerState(
      initialFolder: state.initialFolder,
      folder: folder,
    );
  }
}
