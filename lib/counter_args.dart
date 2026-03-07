import 'package:args/args.dart';

/// Parsed common CLI arguments shared by publisher and subscriber.
typedef CommonArgs = ({
  String key,
  List<String> connectEndpoints,
  List<String> listenEndpoints,
});

/// Parsed publisher CLI arguments (common args plus interval).
typedef PubArgs = ({
  String key,
  List<String> connectEndpoints,
  List<String> listenEndpoints,
  int interval,
});

ArgParser _commonParser() {
  return ArgParser()
    ..addOption('key', abbr: 'k', defaultsTo: 'demo/counter')
    ..addMultiOption('connect', abbr: 'e')
    ..addMultiOption('listen', abbr: 'l');
}

/// Parses common CLI flags: -k/--key, -e/--connect, -l/--listen.
CommonArgs parseCommonArgs(List<String> args) {
  final results = _commonParser().parse(args);
  return (
    key: results.option('key')!,
    connectEndpoints: results.multiOption('connect'),
    listenEndpoints: results.multiOption('listen'),
  );
}

/// Parses publisher CLI flags: common flags plus -i/--interval.
PubArgs parsePubArgs(List<String> args) {
  final parser = _commonParser()
    ..addOption('interval', abbr: 'i', defaultsTo: '1000');
  final results = parser.parse(args);
  return (
    key: results.option('key')!,
    connectEndpoints: results.multiOption('connect'),
    listenEndpoints: results.multiOption('listen'),
    interval: int.parse(results.option('interval')!),
  );
}
