import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

import '../../../../core/theme/app_theme.dart';

/// Syntax-highlighted payload block with Copy and Save actions.
class PayloadCodeView extends StatelessWidget {
  const PayloadCodeView({super.key, required this.code, this.language = 'php'});

  final String code;
  final String language;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    _toast(context, 'Payload copied to clipboard');
  }

  Future<void> _save(BuildContext context) async {
    final dir = Directory.systemTemp;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/payloadhub_$stamp.txt');
    await file.writeAsString(code);
    if (!context.mounted) return;
    _toast(context, 'Saved to ${file.path}');
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      constraints: const BoxConstraints(minHeight: 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  language.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              _HeaderButton(label: 'Copy', icon: Icons.copy, onTap: () => _copy(context)),
              _HeaderButton(label: 'Save', icon: Icons.save_outlined, onTap: () => _save(context)),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            child: HighlightView(
              code,
              language: language,
              theme: atomOneDarkTheme,
              padding: const EdgeInsets.all(8),
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
