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
export const authResponseSchema = z.object({
  id: z.string(),
  username: z.string(),
  email: z.email(),
  token: z.string(),
});

export type IAuthResponse = z.infer<typeof authResponseSchema>;
