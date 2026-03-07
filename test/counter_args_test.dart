import 'package:test/test.dart';
import 'package:zenoh_counter_dart/counter_args.dart';

void main() {
  group('parseCommonArgs', () {
    test('returns defaults when no flags provided', () {
      final result = parseCommonArgs([]);
      expect(result.key, equals('demo/counter'));
      expect(result.connectEndpoints, isEmpty);
      expect(result.listenEndpoints, isEmpty);
    });

    test('parses -k flag', () {
      final result = parseCommonArgs(['-k', 'my/key']);
      expect(result.key, equals('my/key'));
    });

    test('parses --key flag', () {
      final result = parseCommonArgs(['--key', 'my/key']);
      expect(result.key, equals('my/key'));
    });

    test('parses multiple -e connect endpoints', () {
      final result = parseCommonArgs(
        ['-e', 'tcp/host1:7447', '-e', 'tcp/host2:7447'],
      );
      expect(
        result.connectEndpoints,
        equals(['tcp/host1:7447', 'tcp/host2:7447']),
      );
    });

    test('parses multiple -l listen endpoints', () {
      final result = parseCommonArgs(
        ['-l', 'tcp/0.0.0.0:7447', '-l', 'tcp/0.0.0.0:7448'],
      );
      expect(
        result.listenEndpoints,
        equals(['tcp/0.0.0.0:7447', 'tcp/0.0.0.0:7448']),
      );
    });

    test('parses --connect long form', () {
      final result = parseCommonArgs(['--connect', 'tcp/host:7447']);
      expect(result.connectEndpoints, equals(['tcp/host:7447']));
    });
  });

  group('parsePubArgs', () {
    test('returns default interval of 1000', () {
      final result = parsePubArgs([]);
      expect(result.interval, equals(1000));
    });

    test('parses -i flag', () {
      final result = parsePubArgs(['-i', '500']);
      expect(result.interval, equals(500));
    });

    test('parses --interval flag', () {
      final result = parsePubArgs(['--interval', '2000']);
      expect(result.interval, equals(2000));
    });

    test('combines key and interval flags', () {
      final result = parsePubArgs(['-k', 'test/counter', '-i', '100']);
      expect(result.key, equals('test/counter'));
      expect(result.interval, equals(100));
    });
  });
}
