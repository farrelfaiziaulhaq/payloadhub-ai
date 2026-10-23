import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../history/domain/activity_entry.dart';
import '../../../history/presentation/history_providers.dart';
import '../controllers/script_generator_controller.dart';
import '../dashboard_providers.dart';
import 'payload_code_view.dart';

/// Menu 2 — Script Generator: One-Liner Generator + Custom Python Exploit Builder.
class ScriptGeneratorPage extends ConsumerWidget {
  const ScriptGeneratorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.bgElevated,
            child: const TabBar(
              indicatorColor: AppColors.accent,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(text: 'One-Liner Generator'),
                Tab(text: 'Custom Python Exploit Builder'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _OneLinerTab(),
                _PythonBuilderTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — One-Liner Generator (deterministic, offline)
// ---------------------------------------------------------------------------
class _OneLinerTab extends ConsumerStatefulWidget {
  const _OneLinerTab();

  @override
  ConsumerState<_OneLinerTab> createState() => _OneLinerTabState();
}

class _OneLinerTabState extends ConsumerState<_OneLinerTab> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefillDefaults();
  }

  /// Pulls LHOST/LPORT saved in Settings so mobile users do not retype them.
  Future<void> _prefillDefaults() async {
    final storage = ref.read(secureStorageProvider);
    final lhost = await storage.readDefaultLhost();
    final lport = await storage.readDefaultLport();
    if (!mounted) return;
    setState(() {
      if (_ipController.text.isEmpty && (lhost?.trim().isNotEmpty ?? false)) {
        _ipController.text = lhost!.trim();
      }
      if (_portController.text.isEmpty && lport != null) {
        _portController.text = lport.toString();
      }
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    final c = ref.read(scriptGenProvider.notifier);
    c.setIp(_ipController.text.trim());
    c.setPort(_portController.text.trim());
    c.buildOneLiner();

    final s = ref.read(scriptGenProvider);
    if (s.generated.isEmpty) return;
    await ref.read(historyProvider.notifier).add(
          ActivityEntry.create(
            kind: ActivityKind.payload,
            title: '${_catName(s.category)} · ${s.type}',
            detail: s.generated,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Payload dibuat dan disimpan ke riwayat lokal'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(scriptGenProvider);
    final c = ref.read(scriptGenProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final cat in OneLinerCategory.values)
                  _CatChip(
                    label: _catName(cat),
                    selected: s.category == cat,
                    onTap: () => c.setCategory(cat),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Payload Type',
              child: DropdownButton<String>(
                value: s.typeOptions.contains(s.type)
                    ? s.type
                    : s.typeOptions.first,
                isExpanded: true,
                dropdownColor: AppColors.cardAlt,
                items: s.typeOptions
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) c.setType(v);
                },
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'LHOST',
              child: TextFormField(
                controller: _ipController,
                onChanged: c.setIp,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final isReverse = ref.read(scriptGenProvider).category ==
                      OneLinerCategory.reverseShell;
                  return isReverse ? validateIpv4(value) : null;
                },
                decoration: const InputDecoration(
                    hintText: '10.10.14.8',
                    hintStyle: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'LPORT',
              child: TextFormField(
                controller: _portController,
                onChanged: c.setPort,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final isReverse = ref.read(scriptGenProvider).category ==
                      OneLinerCategory.reverseShell;
                  return isReverse ? validatePort(value) : null;
                },
                decoration: const InputDecoration(
                    hintText: '9001',
                    hintStyle: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 46,
              child: FilledButton(
                onPressed: _generate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF0D1117),
                ),
                child: const Text('Generate One-Liner'),
              ),
            ),
            const SizedBox(height: 16),
            if (s.generated.isNotEmpty) ...[
              const Text('Generated Payload',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              PayloadCodeView(code: s.generated, language: _langOf(s.type)),
            ],
          ],
        ),
      ),
    );
  }

  String _catName(OneLinerCategory c) {
    switch (c) {
      case OneLinerCategory.reverseShell:
        return 'Reverse Shell';
      case OneLinerCategory.webShell:
        return 'Web Shell';
      case OneLinerCategory.privesc:
        return 'Privilege Escalation';
    }
  }

  String _langOf(String type) {
    if (type == 'aspx' || type == 'jsp' || type == 'php') return type;
    if (type == 'powershell') return 'powershell';
    if (type == 'python' || type == 'find' || type == 'vim') return 'bash';
    return 'bash';
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF0D1117) : AppColors.textPrimary,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — Custom Python Exploit Builder (uses the backend AI agent)
// ---------------------------------------------------------------------------
class _PythonBuilderTab extends ConsumerStatefulWidget {
  const _PythonBuilderTab();

  @override
  ConsumerState<_PythonBuilderTab> createState() => _PythonBuilderTabState();
}

class _PythonBuilderTabState extends ConsumerState<_PythonBuilderTab> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _pathController = TextEditingController();

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    final c = ref.read(scriptGenProvider.notifier);
    c.setBuildIp(_ipController.text);
    c.setBuildPort(_portController.text);
    c.setBuildPath(_pathController.text);
    await c.buildPythonExploit();

    final result = ref.read(scriptGenProvider).pyResult;
    final blocks = result?.codeBlocks;
    if (result != null && blocks != null && blocks.isNotEmpty) {
      await ref.read(historyProvider.notifier).add(
            ActivityEntry.create(
              kind: ActivityKind.exploit,
              title:
                  'Python exploit · ${_ipController.text.trim()}:${_portController.text.trim()}',
              detail: blocks.first.code,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(scriptGenProvider);
    final c = ref.read(scriptGenProvider.notifier);
    final pyCode = s.pyResult?.codeBlocks;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LabeledField(
              label: 'Target IP',
              child: TextFormField(
                controller: _ipController,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? null : validateIpv4(v),
                decoration: const InputDecoration(
                    hintText: '10.10.10.5',
                    hintStyle: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Target Port',
              child: TextFormField(
                controller: _portController,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? null : validatePort(v),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    hintText: '80',
                    hintStyle: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Vulnerable Path',
              child: TextField(
                controller: _pathController,
                onChanged: c.setBuildPath,
                decoration: const InputDecoration(
                    hintText: '/upload.php or /api/login',
                    hintStyle: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Payload Type',
              child: DropdownButton<String>(
                value: s.buildPayloadType,
                isExpanded: true,
                dropdownColor: AppColors.cardAlt,
                items: const [
                  'Reverse Shell',
                  'Bind Shell',
                  'Command Exec',
                  'File Upload'
                ]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) c.setBuildPayloadType(v);
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 46,
              child: FilledButton(
                onPressed:
                    s.pyStatus == ScriptStatus.loading ? null : _generate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF0D1117),
                ),
                child: s.pyStatus == ScriptStatus.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.bg),
                      )
                    : const Text('Generate exploit.py (AI)'),
              ),
            ),
            if (s.pyError != null) ...[
              const SizedBox(height: 10),
              Text('Error: ${s.pyError}',
                  style:
                      const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
            if (pyCode != null && pyCode.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Generated exploit.py',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              PayloadCodeView(code: pyCode.first.code, language: 'python'),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ],
    );
  }
}
