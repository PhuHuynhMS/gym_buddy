import jwt from "jsonwebtoken";
import { Errors } from "./AppError";

export const ACCESS_TOKEN_EXPIRES_IN_SECONDS = 15 * 60;
export const REFRESH_TOKEN_EXPIRES_IN_SECONDS = 30 * 24 * 60 * 60;

export const generateAccessToken = (
  userId: string,
  sessionId: string,
): { token: string; expiresAt: Date } => {
  const secretKey = process.env.JWT_SECRET_KEY;
  if (!secretKey) {
    throw Errors.INTERNAL(
      "JWT_SECRET_KEY is not defined in environment variables.",
    );
  }

  const expiresAt = new Date(
    Date.now() + ACCESS_TOKEN_EXPIRES_IN_SECONDS * 1000,
  );
  const token = jwt.sign({ id: userId, sessionId }, secretKey, {
    expiresIn: ACCESS_TOKEN_EXPIRES_IN_SECONDS,
  });

  return { token, expiresAt };
};

export const generateToken = (userId: string): string =>
  generateAccessToken(userId, "legacy-session").token;
