import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:logging/logging.dart';
import 'package:phylum/ui/settings/settings.dart';
import 'package:phylum/util/logging/logging.dart';
import 'package:phylum/util/logging/stack_trace.dart';

class LogsSettings extends Settings {
  @override
  IconData get icon => Icons.bug_report;

  @override
  String get title => 'Logs';

  @override
  String get slug => 'logs';

  const LogsSettings();

  @override
  List<StateNotifierProvider> get providers => const [];

  @override
  Widget buildWithoutScaffold(BuildContext context) => LogsPane();
}

class LogsPane extends StatefulWidget {
  const LogsPane({super.key});

  @override
  State<LogsPane> createState() => _LogsPaneState();
}

class _LogsPaneState extends State<LogsPane> {
  final List<LogRecord> records = [];
  final _scrollController = ScrollController();
  late StreamSubscription? sub;
  final prototypeRecord = LogRecord(Level.ALL, '', '', '');

  @override
  void initState() {
    super.initState();
    records.addAll(Log.records);
    sub = Logger.root.onRecord.listen((record) {
      final scroll =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 12;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          records.add(record);
        });
        if (scroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            }
          });
        }
      });
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) =>
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent),
    );
  }

  @override
  void dispose() {
    sub?.cancel();
    // _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(fontFamily: 'RobotoMono'),
      child: ListView.builder(
        itemBuilder: (context, i) {
          final record = records[i];
          return InkWell(
            child: LogRecordSummary(record: record),
            onTap: () {
              String? body = record.error?.toString();
              if (record.stackTrace != null) {
                if (body == null) {
                  body = '';
                } else {
                  body += '\n\n';
                }
                body += cleanupStackTrace(record.stackTrace!);
              }
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Log Entry'),
                  content: SizedBox(
                    width: 560,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          record.object == null
                              ? record.message
                              : stringifyMessage(record.object),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          record.level.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                          softWrap: false,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                        ),
                        Text(
                          dateFormat.format(record.time),
                          style: Theme.of(context).textTheme.bodyMedium,
                          softWrap: false,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                        ),
                        if (body != null)
                          Flexible(
                            child: TextFormField(
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              initialValue: body,
                              readOnly: true,
                              expands: true,
                              maxLines: null,
                              minLines: null,
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: stringifyRecord(record)),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied to Clipboard'),
                            duration: Duration(milliseconds: 1000),
                          ),
                        );
                      },
                      child: Text('Copy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
              // showAlertDialog(context, message: stringifyRecord(record));
            },
          );
        },
        prototypeItem: LogRecordSummary(record: prototypeRecord),
        itemCount: records.length,
        controller: _scrollController,
      ),
    );
  }
}

class LogRecordSummary extends StatelessWidget {
  final LogRecord record;
  final bool standalone;

  LogRecordSummary({required this.record, this.standalone = true})
    : super(key: ValueKey(record));

  @override
  Widget build(BuildContext context) {
    String message = record.object != null
        ? stringifyMessage(record.object)
        : record.message;
    if (standalone && record.error != null) {
      message += ' \u2022 ${record.error}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      child: Row(
        spacing: 12,
        children: [
          Icon(_getIcon(record.level)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                  softWrap: false,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                ),
                Text(
                  '${dateFormat.format(record.time)} | ${record.level.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  softWrap: false,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                ),
              ],
            ),
          ),
          if (standalone && (record.error != null || record.stackTrace != null))
            Icon(Icons.warning_amber_rounded),
          if (standalone)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: stringifyRecord(record)));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied to Clipboard'),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              },
              icon: Icon(Icons.copy),
            ),
        ],
      ),
    );
  }

  IconData _getIcon(Level level) {
    return switch (level) {
      Level.FINEST || Level.FINER || Level.FINE => Icons.bug_report_outlined,
      Level.CONFIG || Level.INFO => Icons.info_outline,
      Level.WARNING ||
      Level.SEVERE ||
      Level.SHOUT => Icons.warning_amber_rounded,
      _ => Icons.question_mark,
    };
  }
}
