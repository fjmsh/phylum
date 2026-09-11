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
          builder: (context, state) => state.shouldAllowKdfSelection
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
        BlocBuilder<CryptConfigCubit, CryptConfigState>(
          bloc: _bloc,
          builder: (context, state) => switch (state.kdf) {
            CryptKDF.argon2 => Argon2ConfigForm(bloc: _bloc),
            CryptKDF.pbkdf2 => throw UnimplementedError(), // TODO: implement
          },
          buildWhen: (previous, current) => previous.kdf != current.kdf,
        ),
        BlocBuilder<CryptConfigCubit, CryptConfigState>(
          bloc: _bloc,
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton.icon(
                icon: Icon(Icons.timer),
                label: state.checkingParams
                    ? const Text('Checking Params')
                    : const Text('Check Parameters'),
                onPressed: state.checkingParams
                    ? null
                    : () async {
                        final result = await _bloc.testArgon2Params();
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
              ),
            );
          },
          buildWhen: (previous, current) =>
              previous.checkingParams != current.checkingParams,
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
      title: const Text('Argon2 Parameters'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Row(
          spacing: 12,
          children: [
            Flexible(
              flex: 1,
              child: _NumberInput(
                key: ValueKey('argon2Memory'),
                initialValue: _bloc.state.argon2Memory,
                onValueUpdated: (value) => _bloc.argon2Memory = value,
                label: 'Memory',
                error: _bloc.state.argon2MemoryError,
              ),
            ),
            Flexible(
              flex: 1,
              child: _NumberInput(
                key: ValueKey('argon2Iterations'),
                initialValue: _bloc.state.argon2Iterations,
                onValueUpdated: (value) => _bloc.argon2Iterations = value,
                label: 'Iterations',
                error: _bloc.state.argon2IterationsError,
              ),
            ),
            Flexible(
              flex: 1,
              child: _NumberInput(
                key: ValueKey('argon2Parallelism'),
                initialValue: _bloc.state.argon2Parallelism,
                onValueUpdated: (value) => _bloc.argon2Parallelism = value,
                label: 'Parallelism',
                error: _bloc.state.argon2ParallelismError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberInput extends StatefulWidget {
  final String? initialValue;
  final void Function(String) onValueUpdated;
  final String? label;
  final String? error;

  const _NumberInput({
    super.key,
    required this.initialValue,
    required this.onValueUpdated,
    required this.label,
    required this.error,
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
            final value = int.tryParse(_controller.text);
            if (value == null) return;
            final str = (value - 1).toString();
            _controller.text = str;
            widget.onValueUpdated(str);
          },
        ),
        suffixIcon: IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            final value = int.tryParse(_controller.text);
            if (value == null) return;
            final str = (value + 1).toString();
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
