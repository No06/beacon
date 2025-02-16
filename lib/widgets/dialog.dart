import 'package:flutter/material.dart';
import 'package:one_launcher/app.dart';

class DialogConfirmButton extends StatelessWidget {
  const DialogConfirmButton({super.key, this.onPressed, this.confirmText});

  final void Function()? onPressed;
  final Widget? confirmText;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: confirmText ?? const Text("确定", style: TextStyle(fontSize: 16)),
    );
  }
}

class DialogCancelButton extends StatelessWidget {
  const DialogCancelButton({super.key, this.onPressed, this.cancelText});

  final void Function()? onPressed;
  final Widget? cancelText;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: cancelText ?? const Text("取消", style: TextStyle(fontSize: 16)),
    );
  }
}

class DefaultDialog extends StatelessWidget {
  const DefaultDialog({
    super.key,
    this.title,
    this.content,
    this.onlyConfirm = false,
    this.onConfirmed,
    this.onCanceled,
    this.confirmText,
    this.cancelText,
    this.actions,
  });

  final Widget? title;
  final Widget? content;
  final bool onlyConfirm;
  final void Function()? onConfirmed;
  final void Function()? onCanceled;
  final Widget? confirmText;
  final Widget? cancelText;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.headlineSmall;
    return AlertDialog(
      titleTextStyle: textTheme!.copyWith(
        fontWeight: FontWeight.bold,
        height: 1,
      ),
      title: title,
      content: content,
      actions: actions ??
          [
            if (!onlyConfirm)
              DialogCancelButton(onPressed: onCanceled, cancelText: cancelText),
            DialogConfirmButton(
              onPressed: onConfirmed,
              confirmText: confirmText,
            ),
          ],
    );
  }
}

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({
    super.key,
    this.title,
    this.content,
    this.onConfirmed,
  });

  final Widget? title;
  final Widget? content;
  final void Function()? onConfirmed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.headlineSmall;
    return AlertDialog(
      titleTextStyle: textTheme!.copyWith(fontWeight: FontWeight.bold),
      title: title ?? const Text("错误"),
      content: Row(
        children: [
          const Icon(Icons.error, size: 36),
          const SizedBox(width: 10),
          if (content != null)
            DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyLarge!,
              child: content!,
            ),
        ],
      ),
      actions: [
        DialogConfirmButton(onPressed: onConfirmed ?? routePop),
      ],
    );
  }
}

class WarningDialog extends StatelessWidget {
  const WarningDialog({
    super.key,
    this.title,
    this.content,
    this.onlyConfirm = false,
    this.onConfirmed,
    this.onCanceled,
  });

  final Widget? title;
  final Widget? content;
  final bool onlyConfirm;
  final void Function()? onConfirmed;
  final void Function()? onCanceled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.headlineSmall;
    return AlertDialog(
      titleTextStyle: textTheme!.copyWith(fontWeight: FontWeight.bold),
      title: title ?? const Text("警告"),
      content: Row(
        children: [
          const Icon(Icons.warning, size: 36),
          const SizedBox(width: 10),
          if (content != null)
            DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyLarge!,
              child: content!,
            ),
        ],
      ),
      actions: [
        if (!onlyConfirm) DialogCancelButton(onPressed: onCanceled ?? routePop),
        DialogConfirmButton(onPressed: onConfirmed),
      ],
    );
  }
}

class FutureDialog<T> extends StatelessWidget {
  const FutureDialog({
    required this.future,
    super.key,
    this.title,
    this.content,
    this.onCanceled,
    this.autoClose = true,
  });

  final Widget? title;
  final Widget? content;
  final VoidCallback? onCanceled;
  final Future<T> future;
  final bool autoClose;

  @override
  Widget build(BuildContext context) {
    return DefaultDialog(
      title: title,
      content: content,
      actions: [
        if (onCanceled != null) DialogCancelButton(onPressed: onCanceled),
      ],
    );
  }
}
