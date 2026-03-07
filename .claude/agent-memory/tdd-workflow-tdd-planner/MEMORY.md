# TDD Planner Memory -- zenoh-counter-dart

## Project State (2026-03-07)
- Scaffold only: single `bin/zenoh_counter_dart.dart` with template args code
- No `lib/` directory yet, no `test/` directory yet
- pubspec.yaml has `args` and `test` but NOT `package:zenoh` yet
- FVM available via `/home/hugo-bluecorn/fvm/bin/fvm`, Dart 3.11.0
- No `.fvmrc` file but CLAUDE.md mandates `fvm dart` for all commands
- analysis_options.yaml uses `package:lints/recommended.yaml`

## zenoh-dart API Patterns (confirmed from examples/tests)
- Two-session TCP test pattern: unique port per test group (17448-17456 used in zenoh-dart)
- Session setup: Config() -> insertJson5('listen/endpoints', '["tcp/127.0.0.1:PORT"]')
- Delays: 500ms after listen session open, 1s after connect session open, 1s for routing
- SHM: ShmProvider(size:) -> allocGcDefragBlocking(n) -> buffer.data pointer write -> buffer.toBytes() -> publisher.putBytes(zbytes)
- After publish: zbytes.dispose() and buffer.dispose() both called
- alloc/allocGcDefragBlocking return nullable ShmMutBuffer?
- toBytes() consumes buffer (subsequent access throws StateError)
- Subscriber.stream is single-subscription, use .first or .take(n).toList()
- ZBytes.fromString() for non-SHM payloads
- session.putBytes(keyExpr, zbytes) for direct session publish

## Test Port Allocation
- zenoh-dart uses ports 17448-17456
- This project should use ports 17460+ to avoid conflicts

## Convention Notes
- Test framework: `package:test` (not flutter_test -- pure Dart CLI project)
- Commit scopes: pub, sub, counter, docs, chore
- KISS/MVP -- no over-engineering
