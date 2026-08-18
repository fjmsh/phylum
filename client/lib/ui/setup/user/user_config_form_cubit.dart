import 'package:bloc/bloc.dart';
import 'package:email_validator/email_validator.dart';
import 'package:phylum/ui/settings/config/config.dart';
import 'package:phylum/ui/setup/user/user_config.dart';

class UserConfigFormState {
  final String email;
  final String? emailError;
  final String name;
  final String? nameError;
  final bool passwordRequired;
  final String password;
  final String? passwordError;

  UserConfigFormState._({
    required this.email,
    required this.name,
    required this.passwordRequired,
    required this.password,
    this.emailError,
    this.nameError,
    this.passwordError,
  });

  factory UserConfigFormState() {
    return UserConfigFormState._(
      email: "",
      name: "",
      passwordRequired: true,
      password: "",
    );
  }

  UserConfigFormState copyWith({
    String? email,
    String? name,
    bool? passwordRequired,
    String? password,
  }) {
    return UserConfigFormState._(
      email: email ?? this.email,
      name: name ?? this.name,
      passwordRequired: passwordRequired ?? this.passwordRequired,
      password: password ?? this.password,
    );
  }

  UserConfigFormState copyWithErrors({
    String? emailError,
    String? nameError,
    String? passwordError,
  }) {
    return UserConfigFormState._(
      email: email,
      name: name,
      passwordRequired: passwordRequired,
      password: password,
      emailError: emailError ?? this.emailError,
      nameError: nameError ?? this.nameError,
      passwordError: passwordError ?? this.passwordError,
    );
  }

  @override
  String toString() {
    return 'DbConfigFormState('
        'email: $email, '
        'emailError: $emailError, '
        'name: $name, '
        'nameError: $nameError, '
        'passwordRequired: $passwordRequired, '
        'password: $password, '
        'passwordError: $passwordError, ';
  }

  @override
  bool operator ==(covariant UserConfigFormState other) {
    if (identical(this, other)) return true;

    return other.email == email &&
        other.emailError == emailError &&
        other.name == name &&
        other.nameError == nameError &&
        other.passwordRequired == passwordRequired &&
        other.password == password &&
        other.passwordError == passwordError;
  }

  @override
  int get hashCode {
    return email.hashCode ^
        emailError.hashCode ^
        name.hashCode ^
        nameError.hashCode ^
        password.hashCode ^
        passwordError.hashCode;
  }
}

class UserConfigFormCubit extends Cubit<UserConfigFormState> {
  UserConfigFormCubit() : super(UserConfigFormState());

  set email(String val) {
    emit(state.copyWith(email: val));
  }

  set name(String val) {
    emit(state.copyWith(name: val));
  }

  set passwordRequired(bool val) {
    emit(state.copyWith(passwordRequired: val));
  }

  set password(String val) {
    emit(state.copyWith(password: val));
  }

  LocalConfig<UserConfigFields>? validate() {
    final newState = state.copyWithErrors(
      emailError: state.email.isEmpty
          ? 'Required'
          : !EmailValidator.validate(state.email)
          ? 'Invalid email address'
          : null,
      nameError: state.name.isEmpty ? 'Required' : null,
      passwordError: state.password.isEmpty ? 'Required' : null,
    );
    if (newState != state) {
      emit(newState);
      return null;
    }
    final config = LocalConfig<UserConfigFields>()
      ..setValue<String>(UserConfigFields.fieldName, state.name)
      ..setValue<String>(UserConfigFields.fieldEmail, state.email);
    if (state.passwordRequired) {
      config.setValue<String>(UserConfigFields.fieldPassword, state.password);
    }
    return config;
  }
}
