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
      setState(() {
        records.add(record);
      });
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 12) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent));
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
    return ListView.builder(
      itemBuilder: (context, i) {
        final record = records[i];
        return InkWell(
          child: LogRecordSummary(record: record),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Log Entry'),
                content: SizedBox(
                  width: 360,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      LogRecordSummary(record: record, standalone: false),
                      if (record.error != null) Text(record.error.toString()),
                      if (record.stackTrace != null)
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 360),
                          child: TextFormField(
                            initialValue: cleanupStackTrace(record.stackTrace!),
                            readOnly: true,
                            expands: true,
                            maxLines: null,
                            minLines: null,
                          ),
                        )
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: stringifyRecord(record)));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Copied to Clipboard'),
                        duration: Duration(milliseconds: 1000),
                      ));
                    },
                    child: Text('Copy'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Okay'),
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
      message += ' | ${record.error}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      child: Row(
        spacing: 12,
        children: [
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
                  '${dateFormat.format(record.time)} \u2022 ${record.level.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  softWrap: false,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                ),
              ],
            ),
          ),
          if (standalone && (record.error != null || record.stackTrace != null))
            Icon(Icons.bug_report),
          if (standalone)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: stringifyRecord(record)));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Copied to Clipboard'),
                  duration: Duration(milliseconds: 1000),
                ));
              },
              icon: Icon(Icons.copy),
            ),
        ],
      ),
    );
  }
}
