import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/util/dialogs.dart';

import 'crypt_config.dart';
import 'crypt_config_cubit.dart';

class CryptConfigForm extends StatelessWidget {
  final CryptConfigCubit _bloc;

  const CryptConfigForm({super.key, required this._bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .end,
      children: [
        BlocBuilder<CryptConfigCubit, CryptConfigState>(
          bloc: _bloc,
          builder: (context, state) =>
              kDebugMode || state.shouldAllowKdfSelection
              ? ListTile(
                  title: Text('KDF'),
                  subtitle: Text(state.kdf.descriptor),
                  leading: Icon(Icons.key),
                  onTap: () async {
                    final kdf = await showOptionsDialog(
                      context,
                      titleText: 'Select KDF',
                      [CryptKDF.argon2, CryptKDF.pbkdf2],
                      (item) => ListTile(title: Text(item.descriptor)),
                    );
                    if (kdf == null || !context.mounted) return;
                    _bloc.kdf = kdf;
                  },
                )
              : const SizedBox(),
          buildWhen: (previous, current) =>
              previous.kdf != current.kdf ||
              previous.shouldAllowKdfSelection !=
                  current.shouldAllowKdfSelection,
        ),
        ListTile(
          dense: true,
          title: const Text('KDF Parameters'),
          trailing: BlocBuilder<CryptConfigCubit, CryptConfigState>(
            bloc: _bloc,
            builder: (context, state) {
              return IconButton(
                icon: Icon(Icons.timer),
                tooltip: state.checkingParams
                    ? 'Checking Params'
                    : 'Check Parameters',
                onPressed: state.checkingParams
                    ? null
                    : () async {
                        final result = await _bloc.testKdfParams();
                        if (!context.mounted) return;
                        switch (result) {
                          case KDFTestFailure():
                            showAlertDialog(
                              context,
                              title: result.title,
                              message: result.details,
                            );
                            break;
                          case KDFTestSuccess(duration: Duration duration):
                            switch (duration.inMilliseconds) {
                              case < 300:
                                showAlertDialog(
                                  context,
                                  title: 'Sub-optimal parameters',
                                  message:
                                      'Password hashing took only ${duration.inMilliseconds}ms. Recommendation is to take at least 300ms',
                                );
                                break;
                              case > 2000:
                                showAlertDialog(
                                  context,
                                  title: 'Sub-optimal parameters',
                                  message:
                                      'Password hashing took ${duration.inMilliseconds}ms. This might be too computationally expensive.',
                                );
                                break;
                              default:
                                showAlertDialog(
                                  context,
                                  message:
                                      'Password hashing took ${duration.inMilliseconds}ms.',
                                );
                            }
                        }
                      },
              );
            },
            buildWhen: (previous, current) =>
                previous.checkingParams != current.checkingParams,
          ),
        ),
        BlocBuilder<CryptConfigCubit, CryptConfigState>(
          bloc: _bloc,
          builder: (context, state) => switch (state.kdf) {
            .argon2 => Argon2ConfigForm(bloc: _bloc),
            .pbkdf2 => Pbkdf2ConfigForm(bloc: _bloc),
          },
          buildWhen: (previous, current) => previous.kdf != current.kdf,
        ),
      ],
    );
  }
}

class Argon2ConfigForm extends StatelessWidget {
  final CryptConfigCubit _bloc;

  const Argon2ConfigForm({super.key, required this._bloc});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(bottom: 12),
      title: Row(
        spacing: 12,
        crossAxisAlignment: .start,
        children: [
          Flexible(
            flex: 1,
            child: BlocBuilder<CryptConfigCubit, CryptConfigState>(
              bloc: _bloc,
              builder: (context, state) {
                return _NumberInput(
                  key: ValueKey('argon2Memory'),
                  initialValue: _bloc.state.argon2Memory,
                  onValueUpdated: (value) => _bloc.argon2Memory = value,
                  label: 'Memory',
                  error: _bloc.state.argon2MemoryError,
                  min: 1,
                  max: 32,
                );
              },
              buildWhen: (previous, current) =>
                  previous.argon2MemoryError != current.argon2MemoryError,
            ),
          ),
          Flexible(
            flex: 1,
            child: BlocBuilder<CryptConfigCubit, CryptConfigState>(
              bloc: _bloc,
              builder: (context, state) {
                return _NumberInput(
                  key: ValueKey('argon2Iterations'),
                  initialValue: _bloc.state.argon2Iterations,
                  onValueUpdated: (value) => _bloc.argon2Iterations = value,
                  label: 'Iterations',
                  error: _bloc.state.argon2IterationsError,
                  min: 1,
                );
              },
              buildWhen: (previous, current) =>
                  previous.argon2IterationsError !=
                  current.argon2IterationsError,
            ),
          ),
          Flexible(
            flex: 1,
            child: BlocBuilder<CryptConfigCubit, CryptConfigState>(
              bloc: _bloc,
              builder: (context, state) {
                return _NumberInput(
                  key: ValueKey('argon2Parallelism'),
                  initialValue: _bloc.state.argon2Parallelism,
                  onValueUpdated: (value) => _bloc.argon2Parallelism = value,
                  label: 'Parallelism',
                  error: _bloc.state.argon2ParallelismError,
                  min: 1,
                );
              },
              buildWhen: (previous, current) =>
                  previous.argon2ParallelismError !=
                  current.argon2ParallelismError,
            ),
          ),
        ],
      ),
    );
  }
}

class Pbkdf2ConfigForm extends StatelessWidget {
  final CryptConfigCubit _bloc;

  const Pbkdf2ConfigForm({super.key, required this._bloc});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(bottom: 12),
      title: Row(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 1,
            child: DropdownButtonFormField<HashFunction>(
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.0,
                  ),
                ),
                label: const Text('Hash Function'),
              ),
              isExpanded: true,
              items: HashFunction.values
                  .map(
                    (f) =>
                        DropdownMenuItem(value: f, child: Text(f.descriptor)),
                  )
                  .toList(growable: false),
              initialValue: _bloc.state.pbkdf2Hash,
              onChanged: (value) => _bloc.pbkdf2Hash = value ?? .sha256,
            ),
          ),
          Flexible(
            flex: 2,
            child: BlocBuilder<CryptConfigCubit, CryptConfigState>(
              bloc: _bloc,
              builder: (context, state) {
                return _NumberInput(
                  key: ValueKey('pbkdf2Iterations'),
                  initialValue: _bloc.state.pbkdf2Iterations,
                  onValueUpdated: (value) => _bloc.pbkdf2Iterations = value,
                  label: 'Iterations',
                  error: _bloc.state.pbkdf2IterationsError,
                  step: 100000,
                  min: 100000,
                );
              },
              buildWhen: (previous, current) =>
                  previous.pbkdf2IterationsError !=
                  current.pbkdf2IterationsError,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberInput extends StatefulWidget {
  final String? initialValue;
  final void Function(String) onValueUpdated;
  final String? label;
  final String? error;
  final int step;
  final int? min;
  final int? max;

  const _NumberInput({
    super.key,
    required this.initialValue,
    required this.onValueUpdated,
    required this.label,
    required this.error,
    this.step = 1,
    this.min,
    this.max,
  });

  @override
  State<_NumberInput> createState() => __NumberInputState();
}

class __NumberInputState extends State<_NumberInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: IconButton(
          icon: Icon(Icons.remove),
          onPressed: () {
            final value = int.tryParse(_controller.text) ?? 0;
            int newValue = value - widget.step;
            if (widget.min != null && newValue < widget.min!) {
              newValue = widget.min!;
            }
            if (widget.max != null && newValue > widget.max!) {
              newValue = widget.max!;
            }
            final str = (newValue).toString();
            _controller.text = str;
            widget.onValueUpdated(str);
          },
        ),
        suffixIcon: IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            final value = int.tryParse(_controller.text) ?? 0;
            int newValue = value + widget.step;
            if (widget.min != null && newValue < widget.min!) {
              newValue = widget.min!;
            }
            if (widget.max != null && newValue > widget.max!) {
              newValue = widget.max!;
            }
            final str = newValue.toString();
            _controller.text = str;
            widget.onValueUpdated(str);
          },
        ),
        labelText: widget.label,
        errorText: widget.error,
      ),
      textAlign: .center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      controller: _controller,
      onChanged: widget.onValueUpdated,
    );
  }
}
