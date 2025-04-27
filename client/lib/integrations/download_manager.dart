export 'download_manager_stub.dart'
    if (dart.library.js_interop) 'download_manager_web.dart'
    if (dart.library.ffi) 'download_manager_vm.dart';
