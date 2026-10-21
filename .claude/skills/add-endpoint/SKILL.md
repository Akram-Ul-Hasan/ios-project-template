---
name: add-endpoint
description: Add an API call to an existing feature: Endpoint case, request/response DTOs, validating mapper, data sources, repository and use case. Use when wiring a new backend endpoint.
---

# Add an endpoint

Work bottom-up inside `Packages/AppModules/Sources/Features/<F>/`:

1. **Endpoint**: add a case to `Data/Endpoint/<F>Endpoint.swift` (path, method, query, body). Set `requiresAuth`
   (defaults to true; false only for login/refresh/public browsing).
2. **DTOs** (`Data/Model/Request|Response`): mirror the OpenAPI spec exactly. Required → non-optional; nullable →
   optional; money is `Decimal`; open enums conform to `UnknownCase`. Requests are `Encodable` (snake_case is automatic).
3. **Mapper** (`Data/Mapper/<Dto>+Entity.swift`): `func toEntity() throws(MappingError)`. Guard every invariant
   (non-empty ids, non-negative money, discount ≤ price …). Defaults only when they mean "absent", with a comment.
4. **Data sources**: add the method to `<F>DataSource`, `Remote` (`client.send(<F>Endpoint.x)`) and `Mock`
   (`mock.load("<f>-<name>")` + a new `App/Resources/Mock/<f>/<f>-<name>.mock.json`).
5. **Repository**: protocol method in Domain; impl maps through the mapper and turns `MappingError` into
   `ResponseError.invalidResponse` with an `AppLogger` error (see `CatalogRepositoryImpl`).
6. **Use case**: one struct per operation with `callAsFunction`; re-run `SharedDomain.Rules` for inputs.
7. **Tests**: `<F>DataTests` — valid fixture maps exactly, missing required field fails decoding, one test per guard;
   `<F>DomainTests` — use case with a hand-written mock repository; `AppTests/MockFixtureTests` — the fixture decodes.
8. Run the `preflight` skill.
