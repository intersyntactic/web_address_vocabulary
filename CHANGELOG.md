# Changelog

## 0.1.1

- `decodeAddressPrefix` refuses any key but `origin` and `pathPrefix`,
  with a `FormatException` naming it (`addressPrefix.x`). An address
  prefix bounds where requests may be granted, so a field the decoder
  would silently drop is refused instead. `encodeAddressPrefix` has
  only ever written those two keys.

## 0.1.0

- `Origin`, `WebPath`, `PathPrefix` and `AddressPrefix`, with their
  `encodeX` / `decodeX` pairs, moved unchanged from `is_effects` 0.14.1,
  which re-exports them. A package that needs only web addresses, such as
  a reply endpoint, no longer depends on `is_effects`.
