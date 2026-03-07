import 'dart:ffi';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:zenoh/zenoh.dart';
import 'package:zenoh_counter_dart/counter_codec.dart';

void main() {
  group('SHM Int64 Publish', () {
    late Session session1;
    late Session session2;
    late ShmProvider provider;

    setUpAll(() async {
      final config1 = Config()
        ..insertJson5('listen/endpoints', '["tcp/127.0.0.1:17460"]')
        ..insertJson5('scouting/multicast/enabled', 'false');
      session1 = Session.open(config: config1);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      final config2 = Config()
        ..insertJson5('connect/endpoints', '["tcp/127.0.0.1:17460"]')
        ..insertJson5('scouting/multicast/enabled', 'false');
      session2 = Session.open(config: config2);

      await Future<void>.delayed(const Duration(seconds: 1));

      provider = ShmProvider(size: 4096);
    });

    tearDownAll(() {
      provider.close();
      session2.close();
      session1.close();
    });

    test(
      'SHM-published int64 received by subscriber with correct value',
      () async {
        final subscriber = session2.declareSubscriber('test/counter/shm');
        addTearDown(subscriber.close);
        final publisher = session1.declarePublisher('test/counter/shm');
        addTearDown(publisher.close);

        await Future<void>.delayed(const Duration(seconds: 1));

        final buf = provider.allocGcDefragBlocking(8);
        expect(buf, isNotNull);

        // Write int64 value 42 as little-endian into buffer
        buf!.data
            .asTypedList(buf.length)
            .buffer
            .asByteData()
            .setInt64(0, 42, Endian.little);
        final zbytes = buf.toBytes();
        publisher.putBytes(zbytes);

        final sample = await subscriber.stream.first.timeout(
          const Duration(seconds: 5),
        );

        expect(sample.payloadBytes, hasLength(8));
        expect(decodeCounter(sample.payloadBytes), equals(42));
      },
    );

    test('Multiple SHM-published int64 values received in order', () async {
      final subscriber = session2.declareSubscriber('test/counter/shm-multi');
      addTearDown(subscriber.close);
      final publisher = session1.declarePublisher('test/counter/shm-multi');
      addTearDown(publisher.close);

      await Future<void>.delayed(const Duration(seconds: 1));

      for (final value in [0, 1, 2]) {
        final buf = provider.allocGcDefragBlocking(8);
        expect(buf, isNotNull, reason: 'SHM alloc failed for value $value');
        buf!.data
            .asTypedList(buf.length)
            .buffer
            .asByteData()
            .setInt64(0, value, Endian.little);
        final zbytes = buf.toBytes();
        publisher.putBytes(zbytes);
      }

      final samples = await subscriber.stream
          .take(3)
          .timeout(const Duration(seconds: 5))
          .toList();

      expect(samples, hasLength(3));
      final values = samples.map((s) => decodeCounter(s.payloadBytes)).toList();
      expect(values, equals([0, 1, 2]));
    });
  });

  group('SHM alloc failure', () {
    test('SHM alloc failure returns null gracefully', () {
      final provider = ShmProvider(size: 4096);
      addTearDown(provider.close);

      // Use alloc() (not allocGcDefragBlocking) because the
      // blocking variant may block indefinitely when size
      // exceeds pool capacity. The non-blocking alloc()
      // returns null immediately on failure.
      final buf = provider.alloc(8192);
      expect(buf, isNull);
    });
  });

  group('SHM zero value', () {
    late Session session1;
    late Session session2;
    late ShmProvider provider;

    setUpAll(() async {
      final config1 = Config()
        ..insertJson5('listen/endpoints', '["tcp/127.0.0.1:17465"]')
        ..insertJson5('scouting/multicast/enabled', 'false');
      session1 = Session.open(config: config1);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      final config2 = Config()
        ..insertJson5('connect/endpoints', '["tcp/127.0.0.1:17465"]')
        ..insertJson5('scouting/multicast/enabled', 'false');
      session2 = Session.open(config: config2);

      await Future<void>.delayed(const Duration(seconds: 1));

      provider = ShmProvider(size: 4096);
    });

    tearDownAll(() {
      provider.close();
      session2.close();
      session1.close();
    });

    test('Zero counter value round-trips through SHM', () async {
      final subscriber = session2.declareSubscriber('test/counter/shm-zero');
      addTearDown(subscriber.close);
      final publisher = session1.declarePublisher('test/counter/shm-zero');
      addTearDown(publisher.close);

      await Future<void>.delayed(const Duration(seconds: 1));

      final buf = provider.allocGcDefragBlocking(8);
      expect(buf, isNotNull);
      buf!.data
          .asTypedList(buf.length)
          .buffer
          .asByteData()
          .setInt64(0, 0, Endian.little);
      final zbytes = buf.toBytes();
      publisher.putBytes(zbytes);

      final sample = await subscriber.stream.first.timeout(
        const Duration(seconds: 5),
      );

      expect(sample.payloadBytes, hasLength(8));
      expect(decodeCounter(sample.payloadBytes), equals(0));
    });
  });
}
