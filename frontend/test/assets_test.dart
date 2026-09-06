import 'package:flutter_test/flutter_test.dart';
import 'package:payloadhub_ai/services/auto_key_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startup does not require bundled credentials', () async {
    await AutoKeyLoader.seed();
  });
}
