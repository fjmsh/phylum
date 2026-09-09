import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/util/dialogs.dart';

import 'crypt_config.dart';
import 'crypt_config_cubit.dart';

class CryptConfigForm extends StatelessWidget {
  final CryptConfigCubit _bloc;
  final bool _mailEnabled;

  const CryptConfigForm({
    super.key,
    required this._bloc,
    required this._mailEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                      titleText: 'Password Login',
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
            CryptKDF.pbkdf2 => throw UnimplementedError(),
          },
          buildWhen: (previous, current) => previous.kdf != current.kdf,
        ),
        BlocBuilder<CryptConfigCubit, CryptConfigState>(
          bloc: _bloc,
          builder: (context, state) => SwitchListTile(
            title: Text('Self-Serve Password Reset'),
            subtitle: !_mailEnabled ? const Text('Requires Email') : null,
            secondary: Icon(Icons.refresh),
            value: _mailEnabled ? state.resetEnabled : false,
            onChanged: _mailEnabled
                ? (value) => _bloc.resetEnabled = value
                : null,
          ),
          buildWhen: (previous, current) =>
              previous.resetEnabled != current.resetEnabled,
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
                initialValue: _bloc.state.argon2Memory,
                onValueUpdated: (value) => _bloc.argon2Memory = value,
                label: 'Memory',
                error: _bloc.state.argon2MemoryError,
              ),
            ),
            Flexible(
              flex: 1,
              child: _NumberInput(
                initialValue: _bloc.state.argon2Iterations,
                onValueUpdated: (value) => _bloc.argon2Iterations = value,
                label: 'Iterations',
                error: _bloc.state.argon2IterationsError,
              ),
            ),
            Flexible(
              flex: 1,
              child: _NumberInput(
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
