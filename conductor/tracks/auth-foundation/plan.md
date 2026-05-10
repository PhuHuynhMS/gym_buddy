# Auth Foundation Plan

- [x] Task 1: Create the Node.js/TypeScript server project structure.
- [x] Task 2: Add MongoDB connection through `process.env.MONGO_URI`.
- [x] Task 3: Implement register/login API with bcrypt and JWT.
- [x] Task 4: Add protected route middleware and user profile API.
- [x] Task 5: Build Flutter login and registration screens.
- [x] Task 6: Connect Flutter auth forms to the backend API.
- [~] Task 7: Store and refresh the auth token securely on the device.
  - [x] Add stateful backend refresh sessions with hashed refresh tokens.
  - [x] Add refresh rotation, reuse detection, and session revocation endpoints.
  - [x] Persist access session metadata with secure storage in Flutter.
  - [x] Persist refresh cookie with Dio CookieJar.
  - [x] Add bootstrap, retry, logout, and session management UI flows.
  - [x] Add Android debug network security config for local HTTPS testing.
  - [ ] Verify end-to-end on a real Android device over local HTTPS.
