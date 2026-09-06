import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../services/free_chatbot_service.dart';
import '../../../../services/secure_storage_service.dart';
import '../controllers/free_chat_controller.dart';
import '../dashboard_providers.dart';

/// Floating "Info Bot" chat panel anchored to the bottom-right corner.
///
/// Read-only / informational only. It is wired to [FreeChatController] + the
/// isolated [FreeChatbotService]; it has NO access to the agent payload tools.
class FloatingChatbot extends ConsumerStatefulWidget {
  const FloatingChatbot({super.key});

  @override
  ConsumerState<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends ConsumerState<FloatingChatbot> {
  bool _open = false;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  late final ProviderSubscription<FreeChatState> _chatSub;
  bool _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
    _chatSub =
        ref.listenManual<FreeChatState>(freeChatControllerProvider, (_, __) => _scrollToEnd());
  }

  @override
  void dispose() {
    _chatSub.close();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text;
    _inputController.clear();
    await ref.read(freeChatControllerProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    return _open ? _chatWindow(context) : _collapsedFab(context);
  }

  Widget _collapsedFab(BuildContext context) {
    return Material(
      color: AppColors.card,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () => setState(() => _open = true),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.smart_toy_outlined, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Info Bot',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatWindow(BuildContext context) {
    final state = ref.watch(freeChatControllerProvider);
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return Container(
      width: 340,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.6),
        boxShadow: const [
          BoxShadow(color: Color(0x88000000), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(context),
          const Divider(height: 1, color: AppColors.border),
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: state.messages.length,
              itemBuilder: (context, index) =>
                  _MessageBubble(message: state.messages[index]),
            ),
          ),
          if (state.status == FreeChatStatus.loading) const _TypingBubble(),
          _inputBar(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_outlined, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Info Chatbot',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _MiniButton(icon: Icons.settings_outlined, onTap: _configure),
          _MiniButton(icon: Icons.close, onTap: () => setState(() => _open = false)),
        ],
      ),
    );
  }

  Widget _inputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
              decoration: InputDecoration(
                hintText: 'Ask a general cybersecurity question...',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                filled: true,
                fillColor: AppColors.bgElevated,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: AppColors.accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _send,
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.send, color: Color(0xFF0D1117), size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _configure() async {
    final storage = ref.read(secureStorageProvider);
    final storedProvider = await storage.readChatProvider();
    final storedKey = await storage.readChatApiKey();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _FreeChatConfigDialog(
        storage: storage,
        initialProvider: storedProvider ?? 'groq',
        initialKey: storedKey ?? '',
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.textSecondary, size: 16),
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final InfoMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == InfoRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accentDim.withValues(alpha: 0.25) : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5, height: 1.4),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
            ),
            SizedBox(width: 8),
            Text('Thinking...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _FreeChatConfigDialog extends StatefulWidget {
  const _FreeChatConfigDialog({
    required this.storage,
    required this.initialProvider,
    required this.initialKey,
  });

  final SecureStorageService storage;
  final String initialProvider;
  final String initialKey;

  @override
  State<_FreeChatConfigDialog> createState() => _FreeChatConfigDialogState();
}

class _FreeChatConfigDialogState extends State<_FreeChatConfigDialog> {
  late String _provider;
  late final TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    _provider = widget.initialProvider;
    _keyController = TextEditingController(text: widget.initialKey);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.storage.writeChatProvider(_provider);
    await widget.storage.writeChatApiKey(_keyController.text.trim());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Info Bot — Free LLM'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _provider,
              decoration: const InputDecoration(labelText: 'Provider'),
              items: [
                for (final e in FreeChatbotService.providerLabels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _provider = v ?? 'groq'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key (stored encrypted via Keystore)',
                hintText: 'gsk_... / AIza...',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Isolated & read-only: the Info Bot cannot access files, the OS, '
              'or the payload system.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
