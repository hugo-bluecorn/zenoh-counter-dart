import 'dart:io';

import 'package:zenoh/zenoh.dart';
import 'package:zenoh_counter_dart/counter_args.dart';
import 'package:zenoh_counter_dart/counter_sub.dart';

void main(List<String> args) {
  final parsed = parseCommonArgs(args);

  final config = Config();
  if (parsed.connectEndpoints.isNotEmpty) {
    final json = parsed.connectEndpoints.map((e) => '"$e"').join(', ');
    config.insertJson5('connect/endpoints', '[$json]');
  }
  if (parsed.listenEndpoints.isNotEmpty) {
    final json = parsed.listenEndpoints.map((e) => '"$e"').join(', ');
    config.insertJson5('listen/endpoints', '[$json]');
  }
  config.insertJson5('scouting/multicast/enabled', 'false');

  final session = Session.open(config: config);

  final handle = startSubscriber(session: session, key: parsed.key);

  print('Subscribing on "${parsed.key}"');

  // Print values as they arrive
  handle.values.listen((value) {
    print('Received: $value');
  });

  ProcessSignal.sigint.watch().listen((_) {
    handle.stop();
    session.close();
    exit(0);
  });
}
