import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:state_notifier/state_notifier.dart';

enum LayoutType {
  collapsed,
  expandedSmall,
  expandedLarge;

  bool get isExpanded => this == LayoutType.expandedSmall || this == LayoutType.expandedLarge;
}

class AppLayoutState {
  final LayoutType type;
  final bool touchUi;

  AppLayoutState({required this.type, required this.touchUi});

  @override
  bool operator ==(Object other) {
    return other is AppLayoutState && other.type == type && other.touchUi == touchUi;
  }

  @override
  int get hashCode => type.hashCode ^ touchUi.hashCode;
}

class AppLayoutManager extends StateNotifier<AppLayoutState> {
  AppLayoutManager() : super(AppLayoutState(type: LayoutType.collapsed, touchUi: true));

  void update(TargetPlatform platform, Size size) {
    final type = size.width < 600
        ? LayoutType.collapsed
        : size.width <= 1200
            ? LayoutType.expandedSmall
            : LayoutType.expandedLarge;
    final touchUi = platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    state = AppLayoutState(type: type, touchUi: touchUi);
  }
}
