import { z } from "zod";

// ============ Register Schema ============
export const registerRequestSchema = z.object({
  username: z
    .string()
    .min(3, "Username must be at least 3 characters")
    .max(30, "Username must not exceed 30 characters"),
  email: z.email("Invalid email format"),
  password: z
    .string()
    .min(6, "Password must be at least 6 characters")
    .max(50, "Password must not exceed 50 characters"),
});

export type RegisterRequest = z.infer<typeof registerRequestSchema>;

// ============ Login Schema ============
export const loginRequestSchema = z.object({
  email: z.email("Invalid email format"),
  password: z
    .string()
    .min(6, "Password must be at least 6 characters")
    .max(50, "Password must not exceed 50 characters"),
});

export type LoginRequest = z.infer<typeof loginRequestSchema>;

// ============ Auth Response Schema ============
export const authUserResponseSchema = z.object({
  id: z.string(),
  username: z.string(),
  email: z.email(),
});

export const authResponseSchema = z.object({
  success: z.literal(true),
  message: z.string(),
  data: z.object({
    user: authUserResponseSchema,
    accessToken: z.string(),
    accessTokenExpiresAt: z.iso.datetime(),
    tokenType: z.literal("Bearer"),
    sessionId: z.string(),
  }),
});

export type IAuthResponse = z.infer<typeof authResponseSchema>;

export const tokenResponseSchema = z.object({
  success: z.literal(true),
  message: z.string(),
  data: z.object({
    accessToken: z.string(),
    accessTokenExpiresAt: z.iso.datetime(),
    tokenType: z.literal("Bearer"),
    sessionId: z.string(),
  }),
});

export type ITokenResponse = z.infer<typeof tokenResponseSchema>;

export const profileUserResponseSchema = authUserResponseSchema.extend({
  avatar: z.string(),
  fitnessLevel: z.enum(["Beginner", "Intermediate", "Advanced"]),
  fcmToken: z.string(),
  createdAt: z.date(),
  updatedAt: z.date(),
});

export const profileResponseSchema = z.object({
  success: z.literal(true),
  message: z.string(),
  data: z.object({
    user: profileUserResponseSchema,
  }),
});

export type IProfileResponse = z.infer<typeof profileResponseSchema>;

export const sessionResponseSchema = z.object({
  id: z.string(),
  deviceName: z.string(),
  platform: z.string(),
  ipAddress: z.string(),
  userAgent: z.string(),
  lastUsedAt: z.iso.datetime(),
  createdAt: z.iso.datetime(),
  expiresAt: z.iso.datetime(),
});

export const sessionsResponseSchema = z.object({
  success: z.literal(true),
  message: z.string(),
  data: z.object({
    sessions: z.array(sessionResponseSchema),
  }),
});

export type ISessionsResponse = z.infer<typeof sessionsResponseSchema>;
