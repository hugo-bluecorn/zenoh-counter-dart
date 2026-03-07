import 'dart:io';

import 'package:zenoh/zenoh.dart';
import 'package:zenoh_counter_dart/counter_args.dart';
import 'package:zenoh_counter_dart/counter_pub.dart';

void main(List<String> args) {
  final parsed = parsePubArgs(args);

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

  final handle = startPublisher(
    session: session,
    key: parsed.key,
    intervalMs: parsed.interval,
  );

  print('Publishing on "${parsed.key}" every ${parsed.interval}ms');

  ProcessSignal.sigint.watch().listen((_) {
    handle.stop();
    session.close();
    exit(0);
  });
}
