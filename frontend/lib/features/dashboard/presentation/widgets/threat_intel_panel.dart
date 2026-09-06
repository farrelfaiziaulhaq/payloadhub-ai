import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/threat_intel_service.dart';
import '../dashboard_providers.dart';
import 'panel_card.dart';

/// Dashboard actions for VirusTotal URL, file, and hash intelligence lookups.
/// Uploads are sent to the backend proxy; the API key is never shown in the UI.
class ThreatIntelPanel extends ConsumerStatefulWidget {
  const ThreatIntelPanel({super.key});

  @override
  ConsumerState<ThreatIntelPanel> createState() => _ThreatIntelPanelState();
}

class _ThreatIntelPanelState extends ConsumerState<ThreatIntelPanel> {
  final _urlController = TextEditingController();
  final _hashController = TextEditingController();
  ThreatScanResult? _result;
  String? _selectedFile;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    _hashController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<ThreatScanResult> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await action();
      if (!mounted) return;
      setState(() => _result = result);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scanUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Masukkan URL yang ingin diperiksa.');
      return;
    }
    await _run(() => ref.read(threatIntelServiceProvider).scanUrl(url));
  }

  Future<void> _scanFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'File tidak dapat dibaca oleh aplikasi.');
      return;
    }
    if (bytes.length > 32 * 1024 * 1024) {
      setState(() => _error =
          'Untuk menjaga stabilitas aplikasi, pilih file maksimal 32 MB.');
      return;
    }
    setState(() => _selectedFile = file.name);
    await _run(
        () => ref.read(threatIntelServiceProvider).scanFile(bytes, file.name));
  }

  Future<void> _lookupHash() async {
    final hash = _hashController.text.trim();
    if (hash.isEmpty) {
      setState(() => _error = 'Masukkan hash MD5, SHA-1, atau SHA-256.');
      return;
    }
    await _run(() => ref.read(threatIntelServiceProvider).lookupHash(hash));
  }

  Future<void> _refresh() async {
    final current = _result;
    if (current == null || current.analysisId.isEmpty) return;
    await _run(
        () => ref.read(threatIntelServiceProvider).refreshAnalysis(current));
  }

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      title: 'VirusTotal Threat Intel',
      subtitle: 'URL phishing, malware file, and hash lookup',
      trailing: [
        PanelIconButton(
            icon: Icons.refresh, onTap: _result == null ? null : _refresh),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InputAction(
            controller: _urlController,
            hint: 'https://suspicious-site.example',
            icon: Icons.link,
            label: 'Scan URL',
            onPressed: _busy ? null : _scanUrl,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _scanFile,
              icon: const Icon(Icons.upload_file, size: 16),
              label: Text(_selectedFile == null
                  ? 'Choose file to scan'
                  : _selectedFile!),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.border),
                alignment: Alignment.centerLeft,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _InputAction(
            controller: _hashController,
            hint: 'SHA-256 / SHA-1 / MD5',
            icon: Icons.fingerprint,
            label: 'Check hash',
            onPressed: _busy ? null : _lookupHash,
          ),
          const SizedBox(height: 10),
          const Text(
            'Upload VirusTotal bersifat publik pada API komunitas. Jangan unggah data rahasia.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
          if (_busy) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            _Message(text: _error!, color: AppColors.danger),
          ],
          if (_result != null) ...[
            const SizedBox(height: 10),
            _ThreatResult(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _InputAction extends StatelessWidget {
  const _InputAction({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, size: 15),
              prefixIconConstraints: const BoxConstraints(minWidth: 32),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 36,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              textStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}

class _ThreatResult extends StatelessWidget {
  const _ThreatResult({required this.result});

  final ThreatScanResult result;

  @override
  Widget build(BuildContext context) {
    final danger = result.malicious > 0;
    final suspicious = result.suspicious > 0;
    final color = danger
        ? AppColors.danger
        : (suspicious ? AppColors.warning : AppColors.accent);
    final label = danger
        ? 'MALICIOUS'
        : (suspicious
            ? 'SUSPICIOUS'
            : (result.isFinished ? 'CLEAN / UNDETECTED' : 'QUEUED'));
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(danger ? Icons.warning_amber : Icons.verified_outlined,
                  size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(result.status,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _Stat(
                  label: 'malicious',
                  value: result.malicious,
                  color: AppColors.danger),
              _Stat(
                  label: 'suspicious',
                  value: result.suspicious,
                  color: AppColors.warning),
              _Stat(
                  label: 'harmless',
                  value: result.harmless,
                  color: AppColors.accent),
              _Stat(
                  label: 'undetected',
                  value: result.undetected,
                  color: AppColors.textSecondary),
            ],
          ),
          if (!result.isFinished && result.analysisId.isNotEmpty) ...[
            const SizedBox(height: 7),
            const Text(
                'Analysis masih berjalan. Tekan refresh untuk mengambil hasil terbaru.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          ],
          ...result.detections.take(3).map(
                (detection) => Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text('${detection.engine}: ${detection.result}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: detection.category == 'malicious'
                              ? AppColors.danger
                              : AppColors.warning,
                          fontSize: 10)),
                ),
              ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Text('$label: $value',
      style:
          TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600));
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: color, fontSize: 11));
}
