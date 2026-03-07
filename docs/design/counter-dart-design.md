# Dart CLI Counter Design

> **Date**: 2026-03-07
> **Source**: CA session in zenoh-dart repo

## Purpose

Pure Dart CLI counter app that validates package:zenoh end-to-end with SHM.
First of three template repos (Dart CLI, C++, Flutter).

## Programs

### counter_pub.dart -- SHM Publisher

1. Parse CLI args (-k, -e, -l, -i)
2. `Zenoh.initLog('error')`
3. Open session (with connect/listen endpoints if provided)
4. Declare publisher on key expression
5. Create ShmProvider (pool size: sufficient for int64 buffers)
6. Loop:
   a. Allocate SHM buffer via `allocGcDefragBlocking(8)`
   b. Write little-endian int64 counter value into buffer
   c. Convert buffer to ZBytes via `toBytes()` (zero-copy, consumes buffer)
   d. Publish via `publisher.putBytes(payload)`
   e. Increment counter
   f. Sleep for interval
7. SIGINT: close publisher, close provider, close session

### counter_sub.dart -- Subscriber

1. Parse CLI args (-k, -e, -l)
2. `Zenoh.initLog('error')`
3. Open session (with connect/listen endpoints if provided)
4. Declare subscriber on key expression
5. Listen on stream:
   - Decode `sample.payloadBytes` as little-endian int64
   - Print received value
6. SIGINT: close subscriber, close session

## Counter Payload Format

- Type: raw little-endian int64 (8 bytes)
- Key expression: `demo/counter` (default)
- Compatible with zenoh-counter-cpp publisher (same binary format)

## SHM Publish Pattern (from zenoh-dart)

```dart
final provider = ShmProvider(size: 4096);
// In loop:
final buf = provider.allocGcDefragBlocking(8);
if (buf != null) {
  buf.data.asTypedList(buf.length).buffer.asByteData().setInt64(0, counter, Endian.little);
  final payload = buf.toBytes(); // consumes buf
  publisher.putBytes(payload);
}
```

## CLI Flags (mirror zenoh-c)

| Flag | Both | Publisher only | Default |
|------|:----:|:--------------:|---------|
| `-k, --key` | yes | | `demo/counter` |
| `-e, --connect` | yes | | (none) |
| `-l, --listen` | yes | | (none) |
| `-i, --interval` | | yes | `1000` (ms) |

## Topologies

| Topology | Publisher args | Subscriber args | Router needed |
|----------|---------------|-----------------|:-------------:|
| Peer multicast | (none) | (none) | no |
| Peer direct | `-l tcp/0.0.0.0:7447` | `-e tcp/localhost:7447` | no |
| Via router | `-e tcp/router:7447` | `-e tcp/router:7447` | yes |

## Testing Approach

- Integration tests using two sessions in same process (TCP listen/connect)
- Publisher writes int64 via SHM, subscriber decodes payloadBytes
- Verify: value received matches value sent
- Verify: SHM alloc/write/toBytes/putBytes pipeline works
- No FFI mocking -- real zenoh calls through native libraries
