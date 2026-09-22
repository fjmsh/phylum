import 'dart:io';

import 'package:flutter/foundation.dart';

final isApple =
    (kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.iOS)) ||
    (!kIsWeb && (Platform.isMacOS || Platform.isIOS));
