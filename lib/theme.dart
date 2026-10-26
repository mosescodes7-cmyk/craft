import 'package:flutter/material.dart';

const kLime = Color(0xFFC8F53C);
const kCard = Color(0xFF1C1C1E);
const kCard2 = Color(0xFF2A2A2D);
const kMuted = Color(0xFF8E8E93);
const kInk = Color(0xFF111111);
const kDanger = Color(0xFFFF5D5D);
const kWarn = Color(0xFFFFB84D);
const kBlue = Color(0xFF7CC4FF);

ThemeData darkTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: kLime,
        onPrimary: kInk,
        surface: kCard,
        error: kDanger,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );

/// Light theme used inside the white sheets / form card.
ThemeData lightTheme() {
  OutlineInputBorder b(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: 1.5),
      );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF9FD000),
      brightness: Brightness.light,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: b(const Color(0xFFE2E2E2)),
      enabledBorder: b(const Color(0xFFE2E2E2)),
      focusedBorder: b(const Color(0xFF9FD000)),
      errorBorder: b(const Color(0xFFD93636)),
      focusedErrorBorder: b(const Color(0xFFD93636)),
    ),
  );
}

void toast(BuildContext context, String msg, {bool bad = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: bad ? Colors.white : kInk,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: bad ? kDanger : kLime,
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 90),
      duration: const Duration(seconds: 2),
    ));
}

/// Rounded pill button. kind: 'primary' | 'ghost' | 'danger'
class PillButton extends StatelessWidget {
  const PillButton(
    this.label, {
    super.key,
    this.onPressed,
    this.kind = 'primary',
    this.icon,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final String kind;
  final IconData? icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final pad = EdgeInsets.symmetric(
        vertical: small ? 10 : 15, horizontal: small ? 18 : 24);
    final min = small ? Size.zero : const Size(0, 52);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: small ? 13 : 15),
          ),
        ),
      ],
    );
    if (kind == 'primary') {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: kLime,
          foregroundColor: kInk,
          disabledBackgroundColor: const Color(0x80C8F53C),
          disabledForegroundColor: kInk,
          shape: const StadiumBorder(),
          padding: pad,
          minimumSize: min,
        ),
        child: child,
      );
    }
    final danger = kind == 'danger';
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? kDanger : (light ? kInk : Colors.white),
        side: BorderSide(
            color: danger
                ? kDanger
                : (light ? const Color(0xFFCCCCCC) : const Color(0xFF666666))),
        shape: const StadiumBorder(),
        padding: pad,
        minimumSize: min,
      ),
      child: child,
    );
  }
}
