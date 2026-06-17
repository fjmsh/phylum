import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

class ProfileView extends StatelessWidget {
  final Function()? onTap;

  const ProfileView({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    return StreamBuilder(
      initialData: account.user,
      stream: account.userNotifier.stream,
      builder: (context, sanpshot) {
        final user = sanpshot.data!;
        return Padding(
          padding: const EdgeInsets.all(6.0),
          child: onTap == null
              ? AvatarView(name: user.name, email: user.email)
              : InkWell(
                  onTap: onTap,
                  child: AvatarView(name: user.name, email: user.email),
                ),
        );
      },
    );
  }
}

class AvatarView extends StatelessWidget {
  final String name;
  final String email;

  const AvatarView({super.key, required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    String initials = name
        .split(' ')
        .map((s) => s.isEmpty ? null : s.substring(0, 1))
        .join('');
    if (initials.isEmpty) {
      initials = email.substring(0, 2);
    }
    final colorScheme = getColorFromString(email);
    return CircularProfileAvatar(
      '',
      initialsText: Text(
        initials,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      foregroundColor: colorScheme.onPrimaryContainer,
      backgroundColor: colorScheme.primaryContainer,
      borderWidth: 1,
      borderColor: colorScheme.onPrimaryContainer,
      radius: 18,
    );
  }
}

ColorScheme getColorFromString(String input) {
  return ColorScheme.fromSeed(
    seedColor: Colors.primaries[(input.hashCode) % Colors.primaries.length],
  );
}
