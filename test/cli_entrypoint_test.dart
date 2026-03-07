import 'dart:ffi';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:zenoh/zenoh.dart';
import 'package:zenoh_counter_dart/counter_args.dart';
import 'package:zenoh_counter_dart/counter_codec.dart';
import 'package:zenoh_counter_dart/counter_pub.dart' as pub;
import 'package:zenoh_counter_dart/counter_sub.dart' as sub;

void main() {
  group('counter_pub publishes values', () {
    late Session session1;
    late Session session2;

    setUpAll(() async {
      final config1 = Config();
      config1.insertJson5('listen/endpoints', '["tcp/127.0.0.1:17462"]');
      config1.insertJson5('scouting/multicast/enabled', 'false');
      session1 = Session.open(config: config1);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      final config2 = Config();
      config2.insertJson5('connect/endpoints', '["tcp/127.0.0.1:17462"]');
      config2.insertJson5('scouting/multicast/enabled', 'false');
      session2 = Session.open(config: config2);

      await Future<void>.delayed(const Duration(seconds: 1));
    });

    tearDownAll(() {
      session2.close();
      session1.close();
    });

    test('counter_pub.dart runs and publishes at least one value', () async {
      final subscriber = session2.declareSubscriber('demo/counter');
      addTearDown(subscriber.close);

      await Future<void>.delayed(const Duration(seconds: 1));

      // Use the extracted publish logic to publish one value
      final handle = pub.startPublisher(
        session: session1,
        key: 'demo/counter',
        intervalMs: 1000,
      );
      addTearDown(handle.stop);

      final sample = await subscriber.stream.first.timeout(
        const Duration(seconds: 5),
      );

      expect(sample.payloadBytes, hasLength(8));
      expect(decodeCounter(sample.payloadBytes), equals(0));
    });
  });

  group('counter_sub receives values', () {
    late Session session1;
    late Session session2;

    setUpAll(() async {
      final config1 = Config();
      config1.insertJson5('listen/endpoints', '["tcp/127.0.0.1:17463"]');
      config1.insertJson5('scouting/multicast/enabled', 'false');
      session1 = Session.open(config: config1);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      final config2 = Config();
      config2.insertJson5('connect/endpoints', '["tcp/127.0.0.1:17463"]');
      config2.insertJson5('scouting/multicast/enabled', 'false');
      session2 = Session.open(config: config2);

      await Future<void>.delayed(const Duration(seconds: 1));
    });

    tearDownAll(() {
      session2.close();
      session1.close();
    });

    test('counter_sub.dart receives and decodes a published value', () async {
      // Start subscriber logic which collects decoded values
      final handle = sub.startSubscriber(
        session: session2,
        key: 'demo/counter',
      );
      addTearDown(handle.stop);

      final publisher = session1.declarePublisher('demo/counter');
      addTearDown(publisher.close);

      await Future<void>.delayed(const Duration(seconds: 1));

      // Publish value 5
      final zbytes = ZBytes.fromUint8List(encodeCounter(5));
      publisher.putBytes(zbytes);

      // Wait for subscriber logic to process the value
      final value = await handle.values.first.timeout(
        const Duration(seconds: 5),
      );

      expect(value, equals(5));
    });
  });

  group('Shutdown', () {
    test('closes all resources without error', () async {
      final config = Config();
      config.insertJson5('scouting/multicast/enabled', 'false');
      final session = Session.open(config: config);

      final publisher = session.declarePublisher('demo/counter');
      final provider = ShmProvider(size: 4096);

      // Close in order: publisher, provider, session
      publisher.close();
      provider.close();
      session.close();

      // Double-close should be safe (idempotent)
      publisher.close();
      provider.close();
      session.close();
    });
  });

  group('Publisher custom args', () {
    test('publisher uses custom key and interval from args', () async {
      final config = Config();
      config.insertJson5('scouting/multicast/enabled', 'false');
      final session = Session.open(config: config);
      addTearDown(session.close);

      final handle = pub.startPublisher(
        session: session,
        key: 'custom/key',
        intervalMs: 100,
      );
      addTearDown(handle.stop);

      expect(handle.key, equals('custom/key'));
      expect(handle.intervalMs, equals(100));
    });
  });
}
