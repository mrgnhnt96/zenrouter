import 'package:flutter/cupertino.dart';
import 'package:zentoast/zentoast.dart';

import 'debug_theme.dart';

// =============================================================================
// TOAST TYPES & DATA
// =============================================================================

/// Kind of toast notification displayed in the debug overlay.
enum ToastType {
  push,
  replace,
  pop,
  remove,
  error,
  info;

  /// Returns the icon, color, and title for this toast type.
  (IconData, Color, String) get display => switch (this) {
    ToastType.push => (
      CupertinoIcons.arrow_right,
      const Color(0xFF2196F3),
      'Push Route',
    ),
    ToastType.replace => (
      CupertinoIcons.arrow_2_squarepath,
      const Color(0xFFFF9800),
      'Replace Route',
    ),
    ToastType.pop => (
      CupertinoIcons.arrow_left,
      const Color(0xFF9C27B0),
      'Pop Route',
    ),
    ToastType.remove => (
      CupertinoIcons.trash,
      const Color(0xFFF44336),
      'Remove Route',
    ),
    ToastType.error => (
      CupertinoIcons.exclamationmark_circle,
      const Color(0xFFF44336),
      'Error',
    ),
    ToastType.info => (
      CupertinoIcons.info_circle,
      const Color(0xFF9E9E9E),
      'Info',
    ),
  };
}

// =============================================================================
// TOAST HELPERS
// =============================================================================

/// Shows a toast notification with the given message and type.
void showDebugToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
}) {
  final (icon, color, title) = type.display;

  Toast(
    height: 52,
    builder:
        (toast) => DebugToastWidget(
          icon: icon,
          color: color,
          title: title,
          message: message,
        ),
  ).show(context);
}

// =============================================================================
// TOAST WIDGET
// =============================================================================

/// A styled toast widget for debug notifications.
class DebugToastWidget extends StatelessWidget {
  const DebugToastWidget({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(
        horizontal: DebugTheme.spacingLg,
        vertical: DebugTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: DebugTheme.backgroundLight,
        borderRadius: BorderRadius.circular(DebugTheme.radiusMd),
        border: Border.all(color: DebugTheme.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: DebugTheme.spacingMd),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: DebugTheme.textPrimary,
                fontSize: DebugTheme.fontSizeXl,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
