import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class DraggableResource extends Draggable<String> {
  final Set<PointerDeviceKind>? supportedDevices;
  final Duration? delay;
  final bool hapticFeedbackOnStart;

  const DraggableResource({
    super.key,
    required super.child,
    required super.feedback,
    super.data,
    super.dragAnchorStrategy,
    super.onDragStarted,
    super.onDragEnd,
    required this.supportedDevices,
    this.delay,
    this.hapticFeedbackOnStart = false,
  });

  @override
  MultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) {
    final recognizer = delay == null
        ? ImmediateMultiDragGestureRecognizer(
            supportedDevices: supportedDevices,
            allowedButtonsFilter: allowedButtonsFilter,
          )
        : DelayedMultiDragGestureRecognizer(
            delay: delay!,
            supportedDevices: supportedDevices,
            allowedButtonsFilter: allowedButtonsFilter,
          );
    return recognizer
      ..onStart = (Offset position) {
        final Drag? result = onStart(position);
        if (result != null && hapticFeedbackOnStart) {
          HapticFeedback.selectionClick();
        }
        return result;
      };
  }
}
