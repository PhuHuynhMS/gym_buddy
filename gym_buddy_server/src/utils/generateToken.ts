import jwt from "jsonwebtoken";
import { Errors } from "./AppError";

export const AUTH_TOKEN_EXPIRES_IN = "30d";

export const generateToken = (userId: string): string => {
  const secretKey = process.env.JWT_SECRET_KEY;
  if (!secretKey) {
    throw Errors.INTERNAL("JWT_SECRET_KEY is not defined in environment variables.");
  }
  const token = jwt.sign({ id: userId }, secretKey, {
    expiresIn: AUTH_TOKEN_EXPIRES_IN,
  });
  return token;
};
