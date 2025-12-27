/// App Dialogs
///
/// Reusable dialog components for confirmations, errors, and alerts.
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Show a confirmation dialog with Yes/No options
///
/// Returns true if confirmed, false if cancelled, null if dismissed
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirmar',
  String cancelText = 'Cancelar',
  Color? confirmColor,
  bool isDangerous = false,
}) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDangerous
                ? AppColors.danger
                : (confirmColor ?? AppColors.primary),
          ),
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

/// Show an error dialog
Future<void> showErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'Aceptar',
}) async {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(buttonText),
        ),
      ],
    ),
  );
}

/// Show a success dialog
Future<void> showSuccessDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'Aceptar',
}) async {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          child: Text(buttonText),
        ),
      ],
    ),
  );
}

/// Show an info dialog
Future<void> showInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'Aceptar',
}) async {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(buttonText),
        ),
      ],
    ),
  );
}

/// Show a loading dialog (non-dismissable)
void showLoadingDialog({
  required BuildContext context,
  String message = 'Cargando...',
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    ),
  );
}

/// Hide the loading dialog
void hideLoadingDialog(BuildContext context) {
  Navigator.of(context).pop();
}

/// Show a delete confirmation dialog (dangerous action)
Future<bool?> showDeleteConfirmDialog({
  required BuildContext context,
  required String itemName,
  String? additionalWarning,
}) async {
  return showConfirmDialog(
    context: context,
    title: 'Confirmar Eliminación',
    message:
        '¿Está seguro de eliminar "$itemName"?'
        '${additionalWarning != null ? '\n\n$additionalWarning' : ''}'
        '\n\nEsta acción no se puede deshacer.',
    confirmText: 'Eliminar',
    isDangerous: true,
  );
}
