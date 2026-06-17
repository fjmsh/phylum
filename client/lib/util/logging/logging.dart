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

final _records = <LogRecord>[];

abstract class Log {
  static Future<void> init() {
    return _init();
  }

  static List<LogRecord> get records => List.unmodifiable(_records);

  static void finest(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) => _logger.log(Level.FINEST, message, error, stackTrace);

  static void finer(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.log(Level.FINER, message, error, stackTrace);

  static void fine(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.log(Level.FINE, message, error, stackTrace);

  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.log(Level.INFO, message, error, stackTrace);

  static void warn(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.log(Level.WARNING, message, error, stackTrace);

  static void severe(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) => _logger.log(Level.SEVERE, message, error, stackTrace);

  static void shout(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.log(Level.SHOUT, message, error, stackTrace);
}

Future<void> _init() async {
  hierarchicalLoggingEnabled = true;
  Logger.root.level = await _getLevel();
  Logger.root.onRecord.listen((record) {
    _records.add(record);
  });

  _logger = Logger('Phylum');
  _logger.level = kDebugMode ? Level.FINE : Level.WARNING;
  _logger.onRecord.listen((record) {
    // ignore: avoid_print
    print('[Phylum] ${stringifyRecord(record, true)}');
  });

  otlLogger =
      (
        LogLevel level,
        dynamic message, {
        dynamic error,
        StackTrace? stackTrace,
      }) {
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

String stringifyRecord(LogRecord record, [bool truncate = false]) {
  String message = record.object != null
      ? stringifyMessage(record.object)
      : record.message;
  String output =
      '${dateFormat.format(record.time)}: [${_stringifyLevel(record.level)}] $message';

  if (record.error != null) {
    output += '\n${record.error.toString()}';
  }

  if (record.stackTrace != null) {
    output +=
        '\n${cleanupStackTrace(record.stackTrace!, methodCount: truncate ? 6 : null)}';
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

String stringifyMessage(dynamic message) {
  final finalMessage = message is Function ? message() : message;
  if (finalMessage is Map || finalMessage is Iterable) {
    var encoder = JsonEncoder.withIndent('  ', (obj) => obj.toString());
    return encoder.convert(finalMessage);
  } else {
    return finalMessage.toString();
  }
}

Future<Level> _getLevel() async {
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
