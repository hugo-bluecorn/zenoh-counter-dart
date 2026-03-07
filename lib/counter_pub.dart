import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:zenoh/zenoh.dart';

/// Handle returned by [startPublisher] to control the publish loop.
class PublisherHandle {
  PublisherHandle._({
    required this.key,
    required this.intervalMs,
    required Publisher publisher,
    required ShmProvider provider,
    required Timer timer,
  }) : _publisher = publisher,
       _provider = provider,
       _timer = timer;

  /// The key expression being published on.
  final String key;

  /// The publish interval in milliseconds.
  final int intervalMs;

  final Publisher _publisher;
  final ShmProvider _provider;
  final Timer _timer;

  /// Stops the publish loop and closes resources.
  void stop() {
    _timer.cancel();
    _publisher.close();
    _provider.close();
  }
}

/// Starts a periodic SHM publisher that increments an int64 counter.
///
/// Returns a [PublisherHandle] to control and stop the publisher.
PublisherHandle startPublisher({
  required Session session,
  required String key,
  required int intervalMs,
}) {
  final provider = ShmProvider(size: 4096);
  final publisher = session.declarePublisher(key);
  var counter = 0;

  final timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
    final buf = provider.allocGcDefragBlocking(8);
    if (buf != null) {
      buf.data
          .asTypedList(buf.length)
          .buffer
          .asByteData()
          .setInt64(0, counter, Endian.little);
      final zbytes = buf.toBytes();
      publisher.putBytes(zbytes);
      counter++;
    }
  });

  // Publish the first value immediately (counter 0).
  final buf = provider.allocGcDefragBlocking(8);
  if (buf != null) {
    buf.data
        .asTypedList(buf.length)
        .buffer
        .asByteData()
        .setInt64(0, counter, Endian.little);
    final zbytes = buf.toBytes();
    publisher.putBytes(zbytes);
    counter++;
  }

  return PublisherHandle._(
    key: key,
    intervalMs: intervalMs,
    publisher: publisher,
    provider: provider,
    timer: timer,
  );
}
