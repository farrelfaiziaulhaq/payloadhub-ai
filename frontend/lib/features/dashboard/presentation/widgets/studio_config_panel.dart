import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/studio_controller.dart';
import '../dashboard_providers.dart';
import 'panel_card.dart';
import 'payload_code_view.dart';

/// Card 3 + AI Agent Prompt: structured payload configuration studio.
class StudioConfigPanel extends ConsumerStatefulWidget {
  const StudioConfigPanel({super.key});

  @override
  ConsumerState<StudioConfigPanel> createState() => _StudioConfigPanelState();
}

class _StudioConfigPanelState extends ConsumerState<StudioConfigPanel> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StudioState>(studioProvider, (prev, next) {
      if (prev?.aiPrompt != next.aiPrompt) {
        _promptController.text = next.aiPrompt;
      }
    });

    final studio = ref.watch(studioProvider);
    final controller = ref.read(studioProvider.notifier);

    final result = studio.result;
    final codeBlocks = result?.codeBlocks ?? const [];
    final hasPayload = codeBlocks.isNotEmpty;

    return PanelCard(
      title: 'Payload Configuration Studio',
      trailing: const [
        PanelIconButton(icon: Icons.more_vert),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OSSelector(value: studio.os, onChanged: controller.setOs),
          const SizedBox(height: 12),
          _TwoColumn(
            left: _LabeledDropdown(
              label: 'Language',
              value: studio.language,
              options: const ['Python', 'PHP', 'Perl', 'PowerShell'],
              onChanged: controller.setLanguage,
            ),
            right: _LabeledDropdown(
              label: 'Bypass Techniques',
              value: studio.bypass,
              options: const [
                'Default',
                'Base64',
                'URL Encoded',
                'Hex',
                'CharCodes'
              ],
              onChanged: controller.setBypass,
            ),
          ),
          const SizedBox(height: 12),
          _LabeledDropdown(
            label: 'Encoder',
            value: studio.encoder,
            options: const ['Auto', 'Base64', 'URL', 'Hex', 'None'],
            onChanged: controller.setEncoder,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: FilledButton(
              onPressed: studio.status == StudioStatus.loading
                  ? null
                  : controller.generate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: const Color(0xFF0D1117),
                textStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: studio.status == StudioStatus.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.bg),
                    )
                  : const Text('Generate Payload'),
            ),
          ),
          const SizedBox(height: 14),
          if (hasPayload)
            PayloadCodeView(
              code: codeBlocks.first.code,
              language: codeBlocks.first.language,
            )
          else
            _PlaceholderCode(offline: studio.error != null),
          if (studio.error != null) ...[
            const SizedBox(height: 8),
            Text(
              'Backend offline: ${studio.error}',
              style: const TextStyle(color: AppColors.danger, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          _AiAgentPromptBar(
            controller: _promptController,
            onSend: () {
              controller.setAiPrompt(_promptController.text);
              controller.generate();
            },
          ),
        ],
      ),
    );
  }
}

class _OSSelector extends StatelessWidget {
  const _OSSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 118,
          child: Text('OS',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
        ),
        Expanded(
          child: _Segmented(
            options: const ['Linux', 'Win', 'Mac'],
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: options.map((opt) {
          final selected = opt == value;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(opt),
              borderRadius: BorderRadius.circular(5),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  opt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF0D1117)
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : options.first,
              isExpanded: true,
              iconEnabledColor: AppColors.textSecondary,
              dropdownColor: AppColors.cardAlt,
              icon: const Icon(Icons.arrow_drop_down, size: 18),
              items: options
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text(o,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 12)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _PlaceholderCode extends StatelessWidget {
  const _PlaceholderCode({required this.offline});

  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        offline
            ? 'Agent unreachable — start the backend (uvicorn).'
            : 'Configure & press Generate Payload.',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _AiAgentPromptBar extends StatelessWidget {
  const _AiAgentPromptBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI Agent Prompt',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 12.5),
                  decoration: const InputDecoration(
                    hintText:
                        'e.g., Generate a PHP reverse shell to 10.10.14.8',
                    hintStyle: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.5),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              InkWell(
                onTap: onSend,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.arrow_forward,
                      color: Color(0xFF0D1117), size: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
