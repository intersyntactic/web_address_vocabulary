# Changelog

## 0.1.0

- `Origin`, `WebPath`, `PathPrefix` and `AddressPrefix`, with their
  `encodeX` / `decodeX` pairs, moved unchanged from `is_effects` 0.14.1,
  which re-exports them. A package that needs only web addresses, such as
  a reply endpoint, no longer depends on `is_effects`.
