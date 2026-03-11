# TDD Implementer Memory

## Project Setup
- No `lib/` or `test/` dirs exist initially -- must create them
- Package name: `zenoh_counter_dart` (import as `package:zenoh_counter_dart/...`)
- `fvm dart test` and `fvm dart analyze` work for all slices
- Native libraries resolved automatically via build hooks (no LD_LIBRARY_PATH needed)

## Testing Patterns
- Use `package:test/test.dart` with `group()` for organization
- `throwsArgumentError` matcher for ArgumentError assertions
- `Uint8List.fromList([...])` for expected byte arrays
- `Uint8List(n)` for zero-filled arrays

## Completed Slices
- Slice 1: Counter Codec -- `lib/counter_codec.dart`, `test/counter_codec_test.dart`
- Slice 2: CLI Argument Parsing -- `lib/counter_args.dart`, `test/counter_args_test.dart`
- Slice 3: SHM Int64 Publish -- `test/shm_publish_test.dart` (integration, no impl file)
- Slice 4: Subscriber Decoding -- `test/subscriber_decode_test.dart` (integration, no impl file, port 17461)
- Slice 5: CLI Entrypoints -- `lib/counter_pub.dart`, `lib/counter_sub.dart`, `bin/counter_pub.dart`, `bin/counter_sub.dart`, `test/cli_entrypoint_test.dart` (ports 17462, 17463)

## CLI Entrypoint Patterns
- Extract logic into lib/ functions (startPublisher, startSubscriber) for testability
- Return handle objects with stop() method for cleanup and metadata for assertions
- SubscriberHandle exposes `values` Stream<int> for decoded values
- PublisherHandle exposes `key` and `intervalMs` for arg verification tests
- Publish first value immediately in startPublisher (don't wait for Timer.periodic)
- Bin entrypoints are thin wrappers: parse args, configure session, call lib function, handle SIGINT
- Removed scaffold `bin/zenoh_counter_dart.dart` in Slice 5

## SHM / zenoh Integration Patterns
- `allocGcDefragBlocking(size)` BLOCKS FOREVER if size > pool capacity; use `alloc(size)` to test oversize (returns null)
- Two-session TCP test setup: session1 listens, 500ms delay, session2 connects, 1s delay for link establishment
- Unique ports per test group to avoid conflicts (17460 for Slice 3 group 1, 17465 for group 2)
- Disable multicast scouting: `config.insertJson5('scouting/multicast/enabled', 'false')`
- SHM write pattern: `buf.data.asTypedList(buf.length).buffer.asByteData().setInt64(0, value, Endian.little)`
- Need `dart:ffi` for Pointer (SHM data ptr) and `dart:typed_data` for Endian
- `zbytes.dispose()` and `buffer.dispose()` after putBytes (but toBytes() consumes buffer so dispose is optional)
- Use `addTearDown(subscriber.close)` / `addTearDown(publisher.close)` for cleanup
- Non-SHM publish: `ZBytes.fromUint8List(encodeCounter(value))` then `publisher.putBytes(zbytes)`

## Args Parsing Patterns
- `package:args` ArgParser: `addOption` for single, `addMultiOption` for repeatable flags
- Use typedef for record types to keep signatures clean
- Extract shared parser into factory function to avoid duplication between common/pub parsers
