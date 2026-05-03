# Check-in Workout Log Spec

## Goal

Provide a fast gym check-in and lightweight workout logging experience.

## Technical Requirements

- QR payloads should be validated server-side.
- Check-ins should be associated with authenticated users and gyms.
- Workout log entry should optimize for low-friction input.
- Backend should keep environment-dependent services configurable through `process.env`.

## Blockers

- QR code format and gym identity source.
- Final workout log fields for first release.
- Camera permission and scanner package selection.
