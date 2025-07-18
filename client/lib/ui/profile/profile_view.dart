import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  final String name;
  final String email;
  final Function()? onTap;

  const ProfileView({super.key, required this.name, required this.email, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: onTap == null
          ? _buildAvatar()
          : InkWell(
              onTap: onTap,
              child: _buildAvatar(),
            ),
    );
  }

  Widget _buildAvatar() {
    String initials = name.split(' ').map((s) => s.isEmpty ? null : s.substring(0, 1)).join('');
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
