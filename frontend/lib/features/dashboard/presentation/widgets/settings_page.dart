import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../dashboard_providers.dart';

/// Menu 4 — Settings: API keys, target defaults, LLM engine + UI tweaks.
/// All sensitive values are persisted via [SecureStorageService] (Keystore).
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _openAi = TextEditingController();
  final _deepSeek = TextEditingController();
  final _gemini = TextEditingController();
  final _shodan = TextEditingController();
  final _virusTotal = TextEditingController();
  final _lhost = TextEditingController();
  final _lport = TextEditingController();

  String _llmEngine = 'deepseek';
  bool _glow = false;
  bool _terminalFont = false;
  bool _sound = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = ref.read(secureStorageProvider);
    final values = await Future.wait([
      storage.readOpenAiKey(),
      storage.readDeepSeekKey(),
      storage.readGeminiKey(),
      storage.readShodanKey(),
      storage.readVirusTotalKey(),
      storage.readDefaultLhost(),
      storage.readDefaultLport(),
      storage.readLlmEngine(),
      storage.readUiGlow(),
      storage.readTerminalFont(),
      storage.readSound(),
    ]);
    if (!mounted) return;
    setState(() {
      _openAi.text = values[0] as String? ?? '';
      _deepSeek.text = values[1] as String? ?? '';
      _gemini.text = values[2] as String? ?? '';
      _shodan.text = values[3] as String? ?? '';
      _virusTotal.text = values[4] as String? ?? '';
      _lhost.text = values[5] as String? ?? '';
      _lport.text = values[6]?.toString() ?? '';
      _llmEngine = (values[7] as String?) ?? 'deepseek';
      _glow = values[8] as bool;
      _terminalFont = values[9] as bool;
      _sound = values[10] as bool;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final storage = ref.read(secureStorageProvider);

    await storage.writeOpenAiKey(_openAi.text.trim());
    await storage.writeDeepSeekKey(_deepSeek.text.trim());
    await storage.writeGeminiKey(_gemini.text.trim());
    await storage.writeShodanKey(_shodan.text.trim());
    await storage.writeVirusTotalKey(_virusTotal.text.trim());
    await storage.writeDefaultLhost(_lhost.text.trim());
    final port = int.tryParse(_lport.text.trim());
    if (port != null) await storage.writeDefaultLport(port);
    await storage.writeLlmEngine(_llmEngine);
    await storage.writeUiGlow(_glow);
    await storage.writeTerminalFont(_terminalFont);
    await storage.writeSound(_sound);

    // Convenience: expose the stored Gemini key to the isolated Info Bot.
    final gemini = _gemini.text.trim();
    if (gemini.isNotEmpty) {
      await storage.writeChatProvider('gemini');
      await storage.writeChatApiKey(gemini);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
            content: Text('Settings saved securely'),
            duration: Duration(seconds: 2)),
      );
  }

  @override
  void dispose() {
    _openAi.dispose();
    _deepSeek.dispose();
    _gemini.dispose();
    _shodan.dispose();
    _virusTotal.dispose();
    _lhost.dispose();
    _lport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionCard(
              title: 'API Configuration',
              subtitle:
                  'Keys are stored locally in encrypted storage; VirusTotal uploads are public on the community API.',
              child: Column(
                children: [
                  _SecretField(label: 'OpenAI API Key', controller: _openAi),
                  _SecretField(
                      label: 'DeepSeek API Key', controller: _deepSeek),
                  _SecretField(label: 'Gemini API Key', controller: _gemini),
                  _SecretField(label: 'Shodan API Key', controller: _shodan),
                  _SecretField(
                      label: 'VirusTotal API Key', controller: _virusTotal),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Target Defaults',
              subtitle: 'Auto-filled into the Payload Studio & generators',
              child: Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'LHOST (pentester IP)',
                      child: TextFormField(
                        controller: _lhost,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? null
                            : validateIpv4(v),
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: 'LPORT',
                      child: TextFormField(
                        controller: _lport,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? null
                            : validatePort(v),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'LLM Engine Selector',
              child: DropdownButtonFormField<String>(
                value: _llmEngine,
                dropdownColor: AppColors.cardAlt,
                decoration:
                    const InputDecoration(labelText: 'Active LLM backend'),
                items: const [
                  DropdownMenuItem(
                      value: 'deepseek', child: Text('DeepSeek API (cloud)')),
                  DropdownMenuItem(
                      value: 'ollama', child: Text('Local Ollama Instance')),
                ],
                onChanged: (v) => setState(() => _llmEngine = v ?? 'deepseek'),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Theme & UI Tweaks',
              child: Column(
                children: [
                  _ToggleRow(
                    label: 'Glow effects',
                    value: _glow,
                    onChanged: (v) => setState(() => _glow = v),
                  ),
                  _ToggleRow(
                    label: 'Terminal font',
                    value: _terminalFont,
                    onChanged: (v) => setState(() => _terminalFont = v),
                  ),
                  _ToggleRow(
                    label: 'Sound effects',
                    value: _sound,
                    onChanged: (v) => setState(() => _sound = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 46,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF0D1117),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SecretField extends StatelessWidget {
  const _SecretField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _LabeledField(
        label: label,
        child: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow(
      {required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
      value: value,
      activeColor: AppColors.accent,
      contentPadding: EdgeInsets.zero,
      dense: true,
      onChanged: onChanged,
    );
  }
}
