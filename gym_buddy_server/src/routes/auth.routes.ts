import express, { Router } from "express";
import { register, login } from "../controllers/authController";
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
 * Response: { success, message, data: { user, token, tokenType, expiresIn } }
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
 * Response: { success, message, data: { user, token, tokenType, expiresIn } }
 */
router.post(
  "/login",
  validateRequest(loginRequestSchema),
  login,
);

export default router;
