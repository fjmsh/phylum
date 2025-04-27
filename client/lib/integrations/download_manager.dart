export 'download_manager_stub.dart'
    if (dart.library.html) 'download_manager_web.dart'
    if (dart.library.io) 'download_manager_vm.dart';
