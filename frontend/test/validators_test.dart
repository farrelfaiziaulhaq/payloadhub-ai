import 'package:flutter_test/flutter_test.dart';
import 'package:payloadhub_ai/core/utils/validators.dart';

void main() {
  group('IPv4 validation', () {
    test('accepts valid dotted-quad addresses', () {
      expect(isValidIpv4('10.10.14.8'), isTrue);
      expect(isValidIpv4('0.0.0.0'), isTrue);
      expect(isValidIpv4('255.255.255.255'), isTrue);
      expect(isValidIpv4(' 192.168.1.20 '), isTrue);
    });

    test('rejects malformed or out-of-range addresses', () {
      expect(isValidIpv4(''), isFalse);
      expect(isValidIpv4('256.1.1.1'), isFalse);
      expect(isValidIpv4('10.10.14'), isFalse);
      expect(isValidIpv4('10.10.14.8.1'), isFalse);
      expect(isValidIpv4('10.10.14.a'), isFalse);
      expect(isValidIpv4('010.010.010.010'), isFalse);
    });

    test('validator returns a user-facing message', () {
      expect(validateIpv4(''), 'IP address is required');
      expect(validateIpv4('999.1.1.1'), 'Enter a valid IPv4 address');
      expect(validateIpv4('10.0.0.1'), isNull);
    });
  });

  group('port validation', () {
    test('accepts 1..65535', () {
      expect(isValidPort('1'), isTrue);
      expect(isValidPort('9001'), isTrue);
      expect(isValidPort('65535'), isTrue);
      expect(isValidPort(' 4444 '), isTrue);
    });

    test('rejects zero, overflow, negatives and text', () {
      expect(isValidPort('0'), isFalse);
      expect(isValidPort('65536'), isFalse);
      expect(isValidPort('-1'), isFalse);
      expect(isValidPort('abc'), isFalse);
      expect(isValidPort(''), isFalse);
    });

    test('validator returns a user-facing message', () {
      expect(validatePort(''), 'Port is required');
      expect(validatePort('70000'), 'Port must be between 1 and 65535');
      expect(validatePort('8080'), isNull);
    });
  });
}
