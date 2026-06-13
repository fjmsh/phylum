import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/util/prefs/prefs.dart';

import 'stack_trace.dart';

const _keyLogLevel = 'logLevel';
final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

late final Logger _logger;

final _records = <String>[];
final _recordsStream = StreamController<String>();

abstract class Log {
  static Future<void> init() {
    return _init();
  }

  static List<String> get records => List.unmodifiable(_records);
  static Stream<String> get recordStream => _recordsStream.stream;

  static void finest(dynamic message,
          [dynamic error, StackTrace? stackTrace]) =>
      _logger.log(Level.FINEST, message, error, stackTrace);

  static void finer(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.log(Level.FINER, message, error, stackTrace);

  static void fine(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.log(Level.FINE, message, error, stackTrace);

  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.log(Level.INFO, message, error, stackTrace);

  static void warn(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.log(Level.WARNING, message, error, stackTrace);

  static void severe(dynamic message,
          [dynamic error, StackTrace? stackTrace]) =>
      _logger.log(Level.SEVERE, message, error, stackTrace);

  static void shout(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.log(Level.SHOUT, message, error, stackTrace);
}

Future<void> _init() async {
  hierarchicalLoggingEnabled = true;
  Logger.root.level = await getLevel();
  Logger.root.onRecord.listen((record) {
    final r = _stringify(record).join('\n');
    _records.add(r);
    _recordsStream.add(r);
  });

  _logger = Logger('Phylum');
  _logger.level = kDebugMode ? Level.FINE : Level.WARNING;
  _logger.onRecord.listen((record) {
    // ignore: avoid_print
    print('[Phylum] ${_stringify(record).join('\n')}');
  });

  otlLogger = (LogLevel level, dynamic message,
      {dynamic error, StackTrace? stackTrace}) {
    final lvl = switch (level) {
      LogLevel.trace => Level.FINEST,
      LogLevel.debug => Level.FINE,
      LogLevel.info => Level.INFO,
      LogLevel.warning => Level.WARNING,
      LogLevel.error => Level.SEVERE,
      LogLevel.fatal => Level.SHOUT,
    };
    _logger.log(lvl, message, error, stackTrace);
  };
}

List<String> _stringify(LogRecord record) {
  final output = <String>[];
  final time = dateFormat.format(record.time);
  final msg = _stringifyMessage(record.message);
  output.add('$time: [${_stringifyLevel(record.level)}] $msg');

  if (record.error != null) {
    output.add(record.error.toString());
  }

  if (record.stackTrace != null) {
    output.add(cleanupStackTrace(record.stackTrace!));
  }

  return output;
}

String _stringifyLevel(Level level) {
  return switch (level) {
    Level.FINEST => 'FIN#',
    Level.FINER => 'FIN+',
    Level.FINE => 'FINE',
    Level.CONFIG => 'CONF',
    Level.INFO => 'INFO',
    Level.WARNING => 'WARN',
    Level.SEVERE => 'SEVR',
    Level.SHOUT => 'FATL',
    _ => level.value.toString(),
  };
}

String _stringifyMessage(dynamic message) {
  final finalMessage = message is Function ? message() : message;
  if (finalMessage is Map || finalMessage is Iterable) {
    var encoder = JsonEncoder.withIndent('  ', (obj) => obj.toString());
    return encoder.convert(finalMessage);
  } else {
    return finalMessage.toString();
  }
}

Future<Level> getLevel() async {
  final prefs = await Prefs.get();
  final level = prefs.getInt(_keyLogLevel);
  if (level != null) {
    for (final l in Level.LEVELS) {
      if (l.value == level) {
        return l;
      }
    }
    return Level('CUSTOM', level);
  }
  return kDebugMode ? Level.FINE : Level.WARNING;
}
