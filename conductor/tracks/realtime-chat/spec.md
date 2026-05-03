# Realtime Chat Spec

## Goal

Support buddy matching and realtime conversation after users agree to train together.

## Technical Requirements

- Server must read ports and external service URLs from `process.env` to support parallel Conductor instances.
- Socket connections authenticate with the same user identity model as HTTP APIs.
- Chat delivery should tolerate app backgrounding through push notification hooks.
- Flutter UI should separate pending, accepted, and declined match states.

## Blockers

- Firebase project setup.
- Final decision on chat persistence schema.
- Realtime authorization rules for match-only chat rooms.
