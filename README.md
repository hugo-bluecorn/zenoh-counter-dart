# zenoh-counter-dart

Pure Dart CLI counter demonstrating [zenoh](https://zenoh.io/) pub/sub with shared memory (SHM) zero-copy publishing.

## What This Is

Two CLI programs that communicate via zenoh:

- **counter_pub** -- Allocates shared memory, writes an incrementing int64 counter, publishes via zero-copy
- **counter_sub** -- Subscribes to the counter topic, decodes and prints received values

```
counter_pub                              counter_sub
  |                                        |
  ShmProvider.alloc(8)                     subscriber.stream.listen()
  |                                        |
  write int64 to SHM buffer               decode sample.payloadBytes
  |                                        |
  buf.toBytes() (zero-copy)               print "Received: 42"
  |
  publisher.putBytes()
```

This is the first of three template repos:

| Repo | Purpose | Status |
|------|---------|--------|
| **zenoh-counter-dart** (this) | Pure Dart CLI, validates package:zenoh + SHM | 0.1.0 |
| zenoh-counter-cpp | C++ SHM publisher, validates cross-language interop | Planned |
| zenoh-counter-flutter | Flutter app, validates desktop + Android UI | Planned |

## Quick Start

### Prerequisites

- [FVM](https://fvm.app/) (Dart/Flutter version manager)

Native libraries (`libzenoh_dart.so`, `libzenohc.so`) are resolved automatically via the upstream package's build hooks.

### Install Dependencies

```bash
fvm dart pub get
```

### Run (Peer Direct -- No Router)

**Terminal 1 -- Subscriber:**
```bash
fvm dart run bin/counter_sub.dart -l tcp/127.0.0.1:7447
```

**Terminal 2 -- Publisher:**
```bash
fvm dart run bin/counter_pub.dart -e tcp/127.0.0.1:7447
```

**Output (subscriber):**
```
Subscribing on "demo/counter"
Received: 0
Received: 1
Received: 2
...
```

Press `Ctrl+C` to stop.

Multiple subscribers can receive from the same publisher -- just run additional `counter_sub.dart` instances. This is fundamental to zenoh's pub/sub model; no code changes needed.

## Topologies

| Topology | Publisher | Subscriber | Router |
|----------|-----------|------------|:------:|
| Peer direct | `-e tcp/host:7447` | `-l tcp/0.0.0.0:7447` | No |
| Peer multicast | (no flags) | (no flags) | No |
| Via router | `-e tcp/router:7447` | `-e tcp/router:7447` | Yes |

See [User Manual](docs/user-manual.md) for detailed setup of each topology.

## CLI Flags

**Both programs:**

| Flag | Description | Default |
|------|-------------|---------|
| `-k, --key` | Key expression | `demo/counter` |
| `-e, --connect` | Connect endpoint (repeatable) | -- |
| `-l, --listen` | Listen endpoint (repeatable) | -- |

**Publisher only:**

| Flag | Description | Default |
|------|-------------|---------|
| `-i, --interval` | Publish interval (ms) | `1000` |

Flags mirror [zenoh-c](https://github.com/eclipse-zenoh/zenoh-c) CLI conventions.

## Counter Payload

- Format: raw little-endian int64 (8 bytes)
- Key expression: `demo/counter` (default)
- Binary-compatible with zenoh-counter-cpp publisher

## SHM Zero-Copy Pipeline

The publisher uses zenoh shared memory to avoid copying the payload:

1. `ShmProvider(size: 4096)` -- create a shared memory pool
2. `provider.allocGcDefragBlocking(8)` -- allocate 8-byte buffer
3. Write int64 directly into the buffer via pointer
4. `buf.toBytes()` -- convert to ZBytes (zero-copy, consumes buffer)
5. `publisher.putBytes(zbytes)` -- publish via zenoh

The subscriber receives the data transparently -- no SHM-specific code needed on the receive side.

## Project Structure

```
bin/
  counter_pub.dart            # SHM publisher entrypoint
  counter_sub.dart            # Subscriber entrypoint
lib/
  counter_codec.dart          # int64 encode/decode (little-endian)
  counter_args.dart           # CLI flag parsing (package:args)
  counter_pub.dart            # Publisher logic (SHM pipeline)
  counter_sub.dart            # Subscriber logic (decode stream)
test/
  counter_codec_test.dart     # 8 unit tests
  counter_args_test.dart      # 10 unit tests
  shm_publish_test.dart       # 4 integration tests
  subscriber_decode_test.dart # 3 integration tests
  cli_entrypoint_test.dart    # 4 integration tests
docs/
  user-manual.md              # Detailed usage with diagrams
  design/                     # Architecture and design docs
```

## Tests

29 tests (18 unit + 11 integration):

```bash
fvm dart test
```

Integration tests use real zenoh sessions over TCP (no mocking).

## Dependencies

- [package:zenoh](https://github.com/hugo-bluecorn/zenoh-dart) -- Dart FFI bindings for zenoh-c v1.7.2
- [package:args](https://pub.dev/packages/args) -- CLI argument parsing

## License

MIT
