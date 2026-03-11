# Feature Notes: Counter Pub/Sub

**Date:** 2026-03-07
**Feature:** zenoh counter pub/sub with SHM

## Research Summary

### zenoh-dart API Surface
- `ShmProvider(size:)` creates shared memory pool
- `allocGcDefragBlocking(size)` returns `ShmMutBuffer?` -- null on failure (verified: does not block forever when size exceeds pool)
- `ShmMutBuffer.data` is `Pointer<Uint8>` for zero-copy writes
- `ShmMutBuffer.toBytes()` converts to `ZBytes` (consumes buffer)
- `Publisher.putBytes(zbytes)` publishes
- `Subscriber.stream` provides `Stream<Sample>` (single-subscription)
- `Sample.payloadBytes` returns `Uint8List`

### Testing Pattern
- Two-session TCP: one session listens, other connects on unique port
- Delays: 500ms listener bind, 1s session establishment, 1s routing propagation
- No FFI mocking -- real zenoh calls through native libraries
- Native libraries resolved automatically via build hooks

### Key Decisions
- Shared codec in `lib/counter_codec.dart` (pure Dart, no zenoh dependency)
- Shared args in `lib/counter_args.dart` (pure Dart, package:args only)
- CLI flags mirror zenoh-c: -k, -e, -l, -i
- Counter payload: raw little-endian int64 (8 bytes)

## Plan Summary

5 slices, 29 tests:
1. Counter Codec (8 tests) -- pure Dart int64 encode/decode
2. CLI Argument Parsing (10 tests) -- pure Dart flag parsing
3. SHM Int64 Publish (4 tests) -- integration, SHM pipeline
4. Subscriber Decoding (3 tests) -- integration, payload decode
5. CLI Entrypoints (4 tests) -- wiring, shutdown, full pipeline

Slices 1 & 2 parallelizable (no zenoh dependency).
Slices 3 & 4 require zenoh dependency.
Slice 5 depends on all prior slices.

## Open Questions (Resolved)

- Q: Does `allocGcDefragBlocking` block forever on oversized request?
- A: No. Verified against C shim -- returns -1 (null in Dart) when allocation fails after GC/defrag attempts. Blocking only applies to transient shortages.
