import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/settings/settings.dart';
import 'package:phylum/util/logging/logging.dart';

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
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    _textController.text = Log.records.join('\n');
    sub = Log.recordStream.listen((msg) {
      _textController.value =
          _textController.value.copyWith(text: '${_textController.text}\n$msg');
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
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      scrollController: _scrollController,
      readOnly: true,
      minLines: null,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
    );
  }
}
