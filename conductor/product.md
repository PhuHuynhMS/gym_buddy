# GymBuddy Connect

GymBuddy Connect is a Flutter mobile app with a Node.js/TypeScript backend that helps users find gyms, discover nearby workout partners, coordinate workouts, and record lightweight training activity.

The product is organized as a monorepo:

- `gym_buddy_app/`: Flutter Android-first client.
- `gym_buddy_server/`: Express, TypeScript, MongoDB backend.

Core capabilities:

- Auth with bcrypt password hashing and JWT sessions.
- Map-based gym and buddy discovery using location and geospatial queries.
- Buddy matching, realtime chat, and push notifications.
- QR check-in and lightweight workout logging.

Conductor tracks should stay small enough for parallel work. Prefer splitting Flutter tracks by screen or flow and backend tracks by API capability or service boundary.
