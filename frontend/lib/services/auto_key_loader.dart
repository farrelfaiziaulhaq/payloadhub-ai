/// Credentials are intentionally never bundled in the Flutter application.
/// Users configure provider keys from Settings, where they are stored through
/// [SecureStorageService], or configure server-side keys in the backend env.
class AutoKeyLoader {
  AutoKeyLoader._();

  static Future<void> seed() async {
    // Kept as an async compatibility hook for the application startup path.
    // All credentials must be entered by the user or injected server-side.
  }
}
