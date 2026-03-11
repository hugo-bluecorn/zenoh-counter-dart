# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Pure Dart CLI counter application demonstrating zenoh pub/sub with shared memory (SHM). This is the first of three template repos validating the zenoh-dart package:

1. **zenoh-counter-dart** (this repo) -- Pure Dart CLI, validates package:zenoh + SHM
2. **zenoh-counter-cpp** -- C++ SHM publisher, validates cross-language interop
3. **zenoh-counter-flutter** -- Flutter app, validates mobile + desktop UI

The counter is the vehicle; the real deliverable is a reusable pattern for Dart + zenoh + SHM applications.

## Project Structure

```
zenoh-counter-dart/
  bin/
    counter_pub.dart          # SHM publisher (incrementing int64)
    counter_sub.dart          # Subscriber (prints received values)
  lib/                        # Shared code (if needed)
  test/                       # Tests
  context/
    roles/                    # CA/CP/CI session prompts
  docs/                       # Planning, design, lessons-learned
  CLAUDE.md
  pubspec.yaml
```

## Dependencies

### package:zenoh (git dependency)

This project depends on the `zenoh` package from the zenoh-dart monorepo:

```yaml
dependencies:
  zenoh:
    git:
      url: https://github.com/hugo-bluecorn/zenoh_dart.git
      path: packages/zenoh
```

The zenoh package provides: Session, Publisher, Subscriber, Sample, ShmProvider, ShmMutBuffer, ZBytes, Config, Zenoh, and related types.

### zenoh-dart Reference (upstream repo)

The zenoh-dart monorepo at `/home/hugo-bluecorn/bluecorn/CSR/git/zenoh_dart/` is the source of truth for the zenoh Dart API. When planning or implementing, consult:

| What | Where |
|------|-------|
| Dart API source | `packages/zenoh/lib/src/*.dart` |
| SHM publish example | `packages/zenoh/example/z_pub_shm.dart` |
| Subscribe example | `packages/zenoh/example/z_sub.dart` |
| Publish example | `packages/zenoh/example/z_pub.dart` |
| Integration tests | `packages/zenoh/test/*.dart` |
| C shim (for understanding FFI) | `src/zenoh_dart.{h,c}` |
| Project conventions | `CLAUDE.md` (comprehensive TDD, testing, architecture docs) |

### Native Libraries Required

Two native shared libraries are required at runtime:
- `libzenoh_dart.so` -- C shim (built from zenoh-dart's `src/`)
- `libzenohc.so` -- zenoh-c runtime (built from zenoh-dart's `extern/zenoh-c/`)

These are resolved automatically via the upstream package's build hooks (`hook/build.dart` for distribution, `DynamicLibrary.open()` for loading). No `LD_LIBRARY_PATH` is needed.

## FVM Requirement

**Dart is NOT on PATH.** All commands must use `fvm`:

```bash
fvm dart ...
fvm dart run bin/counter_pub.dart
fvm dart test
```

## Build & Run

### Running

Native libraries are resolved automatically via build hooks -- no manual setup needed.

```bash
# Run the subscriber (in one terminal)
fvm dart run bin/counter_sub.dart

# Run the SHM publisher (in another terminal)
fvm dart run bin/counter_pub.dart
```

### CLI Flags (mirror zenoh-c conventions)

Both programs support:
- `-k, --key <KEYEXPR>` -- key expression (default: `demo/counter`)
- `-e, --connect <ENDPOINT>` -- connect to endpoint (optional, repeatable)
- `-l, --listen <ENDPOINT>` -- listen on endpoint (optional, repeatable)

Publisher additionally supports:
- `-i, --interval <MS>` -- publish interval in milliseconds (default: 1000)

### Testing

```bash
fvm dart test
```

## Architecture

### Data Flow

```
counter_pub.dart                          counter_sub.dart
  |                                         |
  ShmProvider.alloc(8)                      Session.declareSubscriber('demo/counter')
  |                                         |
  write int64 to SHM buffer                subscriber.stream.listen((sample) {
  |                                           sample.payloadBytes -> int64
  buf.toBytes() -> ZBytes (zero-copy)       })
  |
  publisher.putBytes(zbytes)
```

### Counter Payload

- Format: raw little-endian int64 (8 bytes)
- Published on key expression `demo/counter`
- SHM zero-copy path: alloc -> write -> toBytes -> putBytes

### Topologies Supported

| Topology | Publisher | Subscriber | Router |
|----------|-----------|------------|--------|
| Peer multicast | default config | default config | no |
| Peer direct | `-l tcp/0.0.0.0:7447` | `-e tcp/localhost:7447` | no |
| Via router | `-e tcp/router:7447` | `-e tcp/router:7447` | yes |

## Session Roles

This project uses a three-session workflow:

| Session | Role | Scope |
|---------|------|-------|
| **CA** | Architect / Reviewer | Decisions, reviews, memory |
| **CP** | Planner | Slice decomposition, TDD plans |
| **CI** | Implementer | Code, tests, releases |

Role prompts are in `context/roles/`. Each session reads its role doc before starting.

## Key Conventions

- **CLI flags mirror zenoh-c** -- same flag names and short forms as zenoh-c examples
- **KISS/MVP** -- minimal code, no abstractions beyond what's needed
- **SHM always-on** -- the publisher always uses SHM (that's the point of this template)
- **No isolates** -- zenoh-dart uses NativePort callbacks, no helper isolates needed
- **Build hooks** -- native libraries resolved automatically via `@Native` annotations

## Linting

Uses `very_good_analysis` package (configured in `analysis_options.yaml`).

```bash
fvm dart analyze
```

## Commit Scope Naming

Use the primary module as `<scope>` in commit messages:
- `feat(pub): ...`, `test(pub): ...` for counter_pub
- `feat(sub): ...`, `test(sub): ...` for counter_sub
- `feat(counter): ...` for shared counter logic
- `docs: ...` for documentation changes
- `chore: ...` for build, deps, config changes

## TDD Workflow Plugin

This project uses the **tdd-workflow** Claude Code plugin for structured
test-driven development.

### Plugin Agents

| Agent | Role | Mode |
|-------|------|------|
| **tdd-planner** | Research, decompose, present for approval, write .tdd-progress.md | Read-write (approval-gated) |
| **tdd-implementer** | Writes tests first, then implementation, following the plan | Read-write |
| **tdd-verifier** | Runs complete test suite and static analysis to validate | Read-only |
| **tdd-releaser** | CHANGELOG, push, PR creation | Read-write (Bash only) |

### Available Commands

- **`/tdd-plan <feature description>`** -- Create a TDD implementation plan
- **`/tdd-implement`** -- Start or resume TDD implementation for pending slices
- **`/tdd-release`** -- Finalize and release a completed TDD feature

### Session State

If `.tdd-progress.md` exists at the project root, a TDD session is in progress.
Read it to understand the current state before making changes.

### Testing Constraints

- Native libraries are resolved automatically via build hooks (no `LD_LIBRARY_PATH` needed)
- All test commands via `fvm dart test` (bare `dart` NOT on PATH)
- No mocking of FFI layer -- tests call real zenoh through libzenoh_dart.so
- Two-session testing: use explicit TCP listen/connect with unique ports per test group
- `ShmProvider.allocGcDefragBlocking()` returns `ShmMutBuffer?` (nullable)
- `ShmMutBuffer.toBytes()` consumes the buffer (cannot reuse)
- `Subscriber.stream` is single-subscription (non-broadcast)
- Session, Publisher, Subscriber, ShmProvider all have idempotent close

### zenoh-dart API Reference (Phase 5)

Available classes from `package:zenoh`:
- `Zenoh` -- `initLog(level)` for logger initialization
- `Config` -- `insertJson5(key, value)` for session configuration
- `Session` -- `open(config:)`, `declareSubscriber()`, `declarePublisher()`, `close()`
- `Publisher` -- `put()`, `putBytes()`, `deleteResource()`, `close()`
- `Subscriber` -- `stream` (Stream<Sample>), `close()`
- `Sample` -- `keyExpr`, `payload` (String), `payloadBytes` (Uint8List), `kind`, `encoding`
- `SampleKind` -- `put`, `delete`
- `ShmProvider` -- `ShmProvider(size:)`, `alloc()`, `allocGcDefragBlocking()`, `available`, `close()`
- `ShmMutBuffer` -- `data` (Pointer<Uint8>), `length`, `toBytes()`, `dispose()`
- `ZBytes` -- binary payload container, `markConsumed()`
- `KeyExpr` -- key expression validation
- `Encoding` -- MIME type wrapper
- `ZenohException` -- error type

### Session Directives

When /tdd-plan completes, always show the FULL plan text produced by the planner
agent -- every slice with Given/When/Then, acceptance criteria, and dependencies.
Never summarize or abbreviate the plan output.
