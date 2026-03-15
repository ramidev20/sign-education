import 'package:flutter/material.dart';

class DefaultAvatar extends StatelessWidget {
  final String? name;
  final String? avatarColor; // 🎨 hex color string like "#2196F3"
  final double radius;

  const DefaultAvatar({
    super.key,
    this.name,
    this.avatarColor,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackLetter = (name != null && name!.isNotEmpty)
        ? name![0].toUpperCase()
        : "?";

    // ✅ Default colored avatar using avatarColor
    Color bgColor;
    try {
      bgColor = Color(
        int.parse(
          (avatarColor ?? "#607D8B") // fallback to blueGrey
              .replaceFirst("#", "0xff"),
        ),
      );
    } catch (_) {
      bgColor = Colors.blueGrey; // fallback if parse fails
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        fallbackLetter,
        style: TextStyle(
          fontSize: radius, // proportional text
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
