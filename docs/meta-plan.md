# Meta Plan

> **Date**: 2026-03-07
> **Source**: CA session in zenoh-dart repo

## Three-Repo Strategy

This repo (zenoh-counter-dart) is the first of three, each validating one concern:

1. **zenoh-counter-dart** (this repo) -- Pure Dart CLI, validates package:zenoh + SHM
2. **zenoh-counter-cpp** -- C++ SHM publisher from claude-cpp-template, validates cross-language interop
3. **zenoh-counter-flutter** -- Flutter app, validates desktop + Android UI

## Implementation Order

1. Dart CLI counter (this repo) -- prove the zenoh-dart API works with SHM
2. C++ counter -- prove cross-language SHM interop (Dart sub works with C++ pub)
3. Flutter counter -- prove Flutter + zenoh on desktop and Android

## Native Library Distribution Progression

- **Now (this repo)**: Approach A -- manual LD_LIBRARY_PATH
- **After Flutter MVP**: Approach B -- zenoh_flutter plugin package
- **Long term**: Approach C -- native_assets hook/build.dart

## Cross-Repo Interop

The Dart subscriber from this repo works unchanged with:
- The Dart publisher from this repo (same process or separate)
- The C++ publisher from zenoh-counter-cpp
- Any zenoh publisher on the network

The subscriber doesn't know or care about the publisher's language or SHM usage.

## Template Value

Each repo is designed to be copied as a starting point:
- zenoh-counter-dart -> any Dart CLI + zenoh + SHM project
- zenoh-counter-cpp -> any C++ + zenoh-cpp + SHM project
- zenoh-counter-flutter -> any Flutter + zenoh app
