import 'package:test/test.dart';
import 'package:zenoh/zenoh.dart';
import 'package:zenoh_counter_dart/counter_codec.dart';

void main() {
  group('Subscriber Decoding', () {
    late Session session1;
    late Session session2;

    setUpAll(() async {
      final config1 = Config();
      config1.insertJson5('listen/endpoints', '["tcp/127.0.0.1:17461"]');
      config1.insertJson5('scouting/multicast/enabled', 'false');
      session1 = Session.open(config: config1);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      final config2 = Config();
      config2.insertJson5('connect/endpoints', '["tcp/127.0.0.1:17461"]');
      config2.insertJson5('scouting/multicast/enabled', 'false');
      session2 = Session.open(config: config2);

      await Future<void>.delayed(const Duration(seconds: 1));
    });

    tearDownAll(() {
      session2.close();
      session1.close();
    });

    test('Subscriber decodes int64 from putBytes with raw ZBytes', () async {
      final subscriber = session2.declareSubscriber('test/counter/decode');
      addTearDown(subscriber.close);
      final publisher = session1.declarePublisher('test/counter/decode');
      addTearDown(publisher.close);

      await Future<void>.delayed(const Duration(seconds: 1));

      final zbytes = ZBytes.fromUint8List(encodeCounter(99));
      publisher.putBytes(zbytes);

      final sample = await subscriber.stream.first.timeout(
        const Duration(seconds: 5),
      );

      expect(decodeCounter(sample.payloadBytes), equals(99));
    });

    test('Subscriber decodes sequential counter values', () async {
      final subscriber = session2.declareSubscriber('test/counter/decode-seq');
      addTearDown(subscriber.close);
      final publisher = session1.declarePublisher('test/counter/decode-seq');
      addTearDown(publisher.close);

      await Future<void>.delayed(const Duration(seconds: 1));

      for (final value in [10, 20, 30]) {
        final zbytes = ZBytes.fromUint8List(encodeCounter(value));
        publisher.putBytes(zbytes);
      }

      final samples = await subscriber.stream
          .take(3)
          .timeout(const Duration(seconds: 5))
          .toList();

      expect(samples, hasLength(3));
      final values = samples.map((s) => decodeCounter(s.payloadBytes)).toList();
      expect(values, equals([10, 20, 30]));
    });

    test('Subscriber receives on custom key expression', () async {
      final subscriber = session2.declareSubscriber('my/custom/key');
      addTearDown(subscriber.close);
      final publisher = session1.declarePublisher('my/custom/key');
      addTearDown(publisher.close);

      await Future<void>.delayed(const Duration(seconds: 1));

      final zbytes = ZBytes.fromUint8List(encodeCounter(7));
      publisher.putBytes(zbytes);

      final sample = await subscriber.stream.first.timeout(
        const Duration(seconds: 5),
      );

      expect(sample.keyExpr, equals('my/custom/key'));
      expect(decodeCounter(sample.payloadBytes), equals(7));
    });
  });
}
