/// JSON models matching the backend API contract (see BLUEPRINT.md §3).
class AgentRequestModel {
  AgentRequestModel({
    required this.prompt,
    this.sessionId,
    this.lhost,
    this.lport,
    this.target,
    this.scanData,
  });

  final String prompt;
  final String? sessionId;
  final String? lhost;
  final int? lport;
  final String? target;
  final String? scanData;

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      if (sessionId != null) 'session_id': sessionId,
      if (lhost != null || lport != null || target != null || scanData != null)
        'context': {
          if (lhost != null) 'lhost': lhost,
          if (lport != null) 'lport': lport,
          if (target != null) 'target': target,
          if (scanData != null) 'scan_data': scanData,
        },
    };
  }
}
