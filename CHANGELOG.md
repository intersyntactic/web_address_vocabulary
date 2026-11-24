# Changelog

## 0.1.2

- `WebPath.parse('')` returns `WebPath.root`, the bare site, instead of
  null. `root` is the empty path, so the type's own reader now accepts
  every value it builds. `decodeWebPath` already treated `""` as `root`
  and still does; a caller that wrote
  `raw.isEmpty ? WebPath.root : WebPath.parse(raw)` can call
  `WebPath.parse(raw)`. Nothing sent changes.

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
