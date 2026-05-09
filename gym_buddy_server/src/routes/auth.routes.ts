import express, { Router } from "express";
import {
  getProfile,
  listSessions,
  login,
  logout,
  logoutAll,
  refresh,
  register,
  revokeSessionById,
} from "../controllers/authController";
import { protect } from "../middlewares/auth.middleware";
import { validateRequest } from "../middlewares/validation.middleware";
import {
  registerRequestSchema,
  loginRequestSchema,
} from "../schemas/auth.schema";

const router: Router = express.Router();

/**
 * POST /api/v1/auth/register
 * Register a new user
 * Body: { username, email, password }
 * Response: { success, message, data: { user, accessToken, accessTokenExpiresAt, tokenType, sessionId } }
 */
router.post(
  "/register",
  validateRequest(registerRequestSchema),
  register,
);

/**
 * POST /api/v1/auth/login
 * Login user
 * Body: { email, password }
 * Response: { success, message, data: { user, accessToken, accessTokenExpiresAt, tokenType, sessionId } }
 */
router.post(
  "/login",
  validateRequest(loginRequestSchema),
  login,
);

router.post("/refresh", refresh);
router.post("/logout", protect, logout);
router.post("/logout-all", protect, logoutAll);
router.get("/sessions", protect, listSessions);
router.delete("/sessions/:id", protect, revokeSessionById);

/**
 * GET /api/v1/auth/profile
 * Fetch the current authenticated user profile
 * Header: Authorization: Bearer <token>
 * Response: { success, message, data: { user } }
 */
router.get("/profile", protect, getProfile);

export default router;
