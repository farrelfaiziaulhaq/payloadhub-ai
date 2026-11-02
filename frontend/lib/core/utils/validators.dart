/// Client-side validation helpers (mirror the backend's strict rules).
library;

final RegExp ipv4Pattern =
    RegExp(r'^(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.'
        r'(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.'
        r'(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.'
        r'(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$');

bool isValidIpv4(String value) => ipv4Pattern.hasMatch(value.trim());

bool isValidPort(String value) {
  final port = int.tryParse(value.trim());
  return port != null && port >= 1 && port <= 65535;
}

String? validateIpv4(String? value) {
  if (value == null || value.trim().isEmpty) return 'IP address is required';
  if (!isValidIpv4(value)) return 'Enter a valid IPv4 address';
  return null;
}

String? validatePort(String? value) {
  if (value == null || value.trim().isEmpty) return 'Port is required';
  if (!isValidPort(value)) return 'Port must be between 1 and 65535';
  return null;
}

/// Validates an optional backend URL such as `http://192.168.1.10:8000`.
///
/// An empty value means "use the platform default". A missing scheme is
/// accepted and later normalized to `http://` by `BackendConfig.save`.
String? validateBackendUrl(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;
  final candidate = raw.contains('://') ? raw : 'http://$raw';
  final uri = Uri.tryParse(candidate);
  if (uri == null ||
      uri.host.isEmpty ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return 'Enter a URL like http://192.168.1.10:8000';
  }
  return null;
}
