import 'package:flutter/material.dart';

ColorScheme getColorFromString(String input) {
  return ColorScheme.fromSeed(
    seedColor: Colors.primaries[(input.hashCode) % Colors.primaries.length],
  );
}
