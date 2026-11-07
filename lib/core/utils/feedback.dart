import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Consistent user feedback helpers so every screen reports success and
/// failure the same way.
void showSuccess(BuildContext context, String message) =>
    _show(context, message, Icons.check_circle_rounded, AppColors.resolved);

void showError(BuildContext context, Object error) => _show(
  context,
  _readable(error),
  Icons.error_rounded,
  AppColors.rejected,
);

void _show(BuildContext context, String message, IconData icon, Color color) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

String _readable(Object error) {
  if (error is StateError) return error.message;
  final text = error.toString();
  // Firebase errors look like "[cloud_firestore/permission-denied] message".
  if (text.contains('permission-denied')) {
    return 'You do not have permission to do that.';
  }
  if (text.contains('unavailable') || text.contains('network')) {
    return 'Network problem. Please check your connection and try again.';
  }
  return text.replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '');
}

/// Asks the user to confirm a destructive action.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: destructive ? AppColors.rejected : null,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
