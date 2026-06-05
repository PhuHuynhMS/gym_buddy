# Design: Geospatial Discovery API (Tasks 4 + 5)

## Understanding Summary

- **What:** MongoDB 2dsphere indexes + two REST endpoints for nearby gym and buddy discovery
- **Why:** Core map discovery feature — users find gyms and workout partners near their location
- **Who:** Any user for gyms (public); authenticated users only for buddies (privacy)
- **Constraints:** 5 km default radius, 20 km hard cap, 20 results per page (offset), results sorted by distance
- **Non-goals:** Buddy matching/relationship logic, gym CRUD/moderation, real-time location streaming

## Assumptions

- `radius` param is in kilometres
- `distanceKm` field is included in every response item (Flutter displays "X km away")
- Indexes registered via `Schema.index()` in model files — no separate migration
- Endpoints live at `GET /api/v1/gyms/nearby` and `GET /api/v1/buddies/nearby`
- `UnauthorizedError` reused from auth-foundation track

---

## Indexes (Task 4)

### Gym.ts
```ts
GymSchema.index({ location: "2dsphere" });
```

### BuddyAvailability.ts
```ts
BuddyAvailabilitySchema.index({ location: "2dsphere" });
BuddyAvailabilitySchema.index({ location: "2dsphere", status: 1, availableUntil: 1 });
```

Compound index on BuddyAvailability because every query filters `status + availableUntil` alongside the geospatial field. MongoDB requires `2dsphere` as the first field in a compound index when using `$nearSphere`.

---

## Shared Zod Query Schema

Added to `src/schemas/maps.schema.ts`:

```ts
export const nearbyQuerySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  lng: z.coerce.number().min(-180).max(180),
  radius: z.coerce.number().min(0.1).max(20).default(5),
  limit: z.coerce.number().int().min(1).max(50).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

export type NearbyQuery = z.infer<typeof nearbyQuerySchema>;
```

`z.coerce.number()` handles HTTP query params arriving as strings.

---

## API Contract (Task 5)

### GET /api/v1/gyms/nearby — Public

**Query params:** `lat`, `lng`, `radius?` (km, default 5, max 20), `limit?` (default 20, max 50), `offset?` (default 0)

**Response 200:**
```json
{
  "data": [
    {
      "id": "abc123",
      "name": "California Fitness",
      "address": "123 Nguyen Hue, Q1",
      "location": { "type": "Point", "coordinates": [106.700, 10.776] },
      "distanceKm": 1.23,
      "amenities": ["pool", "sauna"],
      "verificationStatus": "verified"
    }
  ],
  "pagination": { "limit": 20, "offset": 0, "hasMore": true }
}
```

**Filter:** `verificationStatus != "rejected"`

---

### GET /api/v1/buddies/nearby — Protected (JWT required)

**Query params:** same as gyms

**Response 200:** same envelope shape, items include buddy availability fields + `distanceKm`

**Filter:** `status: "active"` AND `availableUntil > now` AND `visibility: "public"`

---

### Error Responses

| Scenario | Status | error |
|---|---|---|
| Missing `lat` or `lng` | 400 | `"ValidationError"` |
| `radius` > 20 | 400 | `"ValidationError"` |
| Missing/invalid JWT (buddies) | 401 | `"Unauthorized"` |

```json
{
  "error": "ValidationError",
  "message": "radius must not exceed 20 km",
  "details": { "field": "radius", "value": 50 }
}
```

---

## MongoDB Query Pattern

Both controllers use `$geoNear` aggregation (not `find + $nearSphere`) so MongoDB injects `distanceKm` automatically via `distanceMultiplier: 0.001` (metres → km). No Haversine calculation needed in application code.

**Gym pipeline:**
```ts
Gym.aggregate([
  {
    $geoNear: {
      near: { type: "Point", coordinates: [lng, lat] },
      distanceField: "distanceKm",
      distanceMultiplier: 0.001,
      maxDistance: radius * 1000,
      spherical: true,
      query: { verificationStatus: { $ne: "rejected" } },
    },
  },
  { $skip: offset },
  { $limit: limit },
  { $project: { __v: 0 } },
]);
```

**Buddy pipeline** — same structure, different `query` filter:
```ts
query: {
  status: "active",
  availableUntil: { $gt: new Date() },
  visibility: "public",
}
```

---

## File Structure

```
src/
  routes/
    gyms.routes.ts          ← GET /api/v1/gyms/nearby (no auth)
    buddies.routes.ts       ← GET /api/v1/buddies/nearby (+ authMiddleware)
  controllers/
    gyms.controller.ts
    buddies.controller.ts
  schemas/
    maps.schema.ts          ← add nearbyQuerySchema here
  models/
    Gym.ts                  ← add GymSchema.index(...)
    BuddyAvailability.ts    ← add compound index
```

---

## Testing Strategy

Integration tests with `mongodb-memory-server` (not unit tests — mock DB cannot verify query correctness).

| Test case | Endpoint |
|---|---|
| Missing `lat` or `lng` → 400 | Both |
| `radius` > 20 → 400 | Both |
| Results sorted by `distanceKm` ascending | Both |
| `rejected` gym excluded | `/gyms/nearby` |
| `paused` / `expired` / `matches_only` buddy excluded | `/buddies/nearby` |
| No JWT → 401 | `/buddies/nearby` |
| Offset pagination correct | Both |

---

## Decision Log

| # | Decision | Alternatives | Reason |
|---|---|---|---|
| 1 | Design Tasks 4+5 together | Task 4 alone | Index design depends on Task 5 query patterns |
| 2 | Sort by distance (`$geoNear`) | `$geoWithin` unsorted | Better UX — "X km away" |
| 3 | 5 km default, 20 km cap, same for both | Different per type | Simpler, sufficient for MVP |
| 4 | Offset pagination, 20/page | Cursor-based | MVP sufficient; geospatial doesn't need real-time consistency |
| 5 | Gyms public, buddies protected | Both protected | Gym data is non-personal; buddy availability is privacy-sensitive |
| 6 | Buddy: `active` + time-valid + `public` only | Looser filter | Avoid exposing stale or private data |
| 7 | Gym: exclude `rejected` only | Verified only | DB is sparse at launch |
| 8 | Separate controllers, shared Zod schema | Shared service layer | YAGNI — two endpoints differ enough |
| 9 | `$geoNear` aggregation | `find` + Haversine | MongoDB computes distance automatically, less code |
| 10 | URL versioning `/api/v1/` | No versioning | Avoids breaking changes later |
