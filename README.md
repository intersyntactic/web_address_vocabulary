# is_web_address_vocabulary

Web addresses as values that can't name somewhere other than where they
were decided to go, with their JSON. It holds types and does nothing, and
depends on nothing but `dart:core`.

- `Origin`: an http(s) site, scheme, host and port only. `Origin.parse`
  returns null for anything carrying a path, query, fragment or
  credentials.
- `WebPath`: a path on an origin, made only by `parse`, which returns null
  unless the path is exactly what will be sent: a leading `/`, no
  authority, no `..`, `@` or `#`, and nothing a URI parser or a second
  decode would rewrite.
- `PathPrefix`: the start of the paths something may reach, compared by
  canonical segments, so `19:` and `19%3A` are the same segment. `/` is the
  whole site.
- `AddressPrefix`: an `Origin` and a `PathPrefix` on it, such as where a
  trajectory's replies go or how far a fetch grant reaches.

Each has an `encodeX` / `decodeX` pair. A decode throws a
`FormatException` naming the field. An `AddressPrefix` is
`{"origin": "https://…", "pathPrefix": "/…/"}`.

`is_effects` re-exports all of this, so its `AddressPrefix` and this one
are the same type.
