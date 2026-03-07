# Changelog

## 0.1.1 -- 2026-03-07

### Changed
- Switch linting from `package:lints` to `very_good_analysis` ^10.2.0
- Fix all lint issues: cascade invocations, package imports, line length, discarded futures
- Suppress `avoid_print` for `bin/` (CLI apps print by design)
- Fix zenoh-dart git dependency URL (underscore not hyphen)
- Add `publish_to: none` to pubspec.yaml

## 0.1.0 -- 2026-03-07

### Added
- SHM publisher (`counter_pub.dart`) with zero-copy int64 publish pipeline
- Subscriber (`counter_sub.dart`) with little-endian int64 decoding
- Shared counter codec (`lib/counter_codec.dart`) for int64 encode/decode
- CLI argument parsing mirroring zenoh-c conventions (-k, -e, -l, -i)
- Three topology support: peer multicast, peer direct, via router
- User manual with Mermaid sequence diagram and flowchart
- 29 tests (unit + integration) with real zenoh calls
