import 'dart:async';

import 'package:zenoh/zenoh.dart';
import 'package:zenoh_counter_dart/counter_codec.dart';

/// Handle returned by [startSubscriber] to control the subscription.
class SubscriberHandle {
  SubscriberHandle._({
    required Subscriber subscriber,
    required StreamController<int> controller,
  }) : _subscriber = subscriber,
       _controller = controller;

  final Subscriber _subscriber;
  final StreamController<int> _controller;

  /// Stream of decoded counter values.
  Stream<int> get values => _controller.stream;

  /// Stops the subscriber and closes the stream.
  void stop() {
    unawaited(_subscription?.cancel());
    _subscriber.close();
    unawaited(_controller.close());
  }

  StreamSubscription<Sample>? _subscription;
}

/// Starts a subscriber that decodes int64 counter values from
/// [Sample.payloadBytes].
///
/// Returns a [SubscriberHandle] with a [SubscriberHandle.values] stream
/// of decoded integers.
SubscriberHandle startSubscriber({
  required Session session,
  required String key,
}) {
  final subscriber = session.declareSubscriber(key);
  final controller = StreamController<int>();

  final handle =
      SubscriberHandle._(
          subscriber: subscriber,
          controller: controller,
        )
        .._subscription = subscriber.stream.listen((sample) {
          if (sample.payloadBytes.length == 8) {
            final value = decodeCounter(sample.payloadBytes);
            controller.add(value);
          }
        });

  return handle;
}
