# Auth Foundation Spec

## Goal

Provide secure account creation and login across the Node.js API and Flutter app.

## Technical Requirements

- Backend reads configuration from environment variables, especially `MONGO_URI`, `PORT`, and `JWT_SECRET_KEY`.
- Passwords are hashed with bcrypt before storage.
- JWTs are signed server-side and sent to the Flutter client after successful login.
- Protected APIs reject missing or invalid tokens.
- Flutter stores tokens using secure storage once that dependency is introduced.

## Blockers

- Confirm final profile fields before building user profile editing.
- Choose secure token storage package for Flutter.
- Decide whether refresh tokens are needed for the first demo scope.
