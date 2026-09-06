import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/dashboard_models.dart';
import 'panel_card.dart';

/// Card 2: Verified Payload Library — a grid of ready-to-use payload chips.
class PayloadLibraryPanel extends StatelessWidget {
  const PayloadLibraryPanel({super.key});

  static const _categories = <PayloadCategory>[
    PayloadCategory('RCE-Linux'),
    PayloadCategory('SQLi-Error'),
    PayloadCategory('SQLi-TimeBased'),
    PayloadCategory('SQLi-Blind'),
    PayloadCategory('LFI-Payload'),
    PayloadCategory('RCE-Windows'),
    PayloadCategory('XSS-Stored'),
    PayloadCategory('XSS-Reflected'),
    PayloadCategory('SSRF-Open'),
    PayloadCategory('SSTI-Jinja'),
    PayloadCategory('Deserialization'),
    PayloadCategory('XXE-Payload'),
    PayloadCategory('Upload-Bypass'),
    PayloadCategory('Path-Traversal'),
    PayloadCategory('Command-Inject'),
    PayloadCategory('LDAP-Injection'),
  ];

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      title: 'Verified Payload Library',
      trailing: const [
        PanelIconButton(icon: Icons.more_vert),
        PanelIconButton(icon: Icons.open_in_full),
      ],
      body: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _categories.map((c) => _Chip(label: c.label)).toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
    );
  }
}
