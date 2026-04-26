import jwt from "jsonwebtoken";
import { Errors } from "./AppError";

export const generateToken = (userId: string): string => {
  const secretKey = process.env.JWT_SECRET_KEY;
  if (!secretKey) {
    throw Errors.INTERNAL("JWT_SECRET_KEY is not defined in environment variables.");
  }
  const token = jwt.sign({ id: userId }, secretKey, { expiresIn: "30d" });
  return token;
};
