import type { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import User from "../models/User";
import { Errors } from "../utils/AppError";

interface JwtPayload {
  id?: string;
}

export const protect = async (
  req: Request,
  _res: Response,
  next: NextFunction,
) => {
  try {
    const authorization = req.headers.authorization;

    if (!authorization?.startsWith("Bearer ")) {
      throw Errors.UNAUTHORIZED("Authorization token is required");
    }

    const token = authorization.split(" ")[1];
    if (!token) {
      throw Errors.UNAUTHORIZED("Authorization token is required");
    }

    const secretKey = process.env.JWT_SECRET_KEY;
    if (!secretKey) {
      throw Errors.INTERNAL(
        "JWT_SECRET_KEY is not defined in environment variables.",
      );
    }

    const decoded = jwt.verify(token, secretKey) as JwtPayload;
    if (!decoded.id) {
      throw Errors.UNAUTHORIZED("Token is invalid");
    }

    const user = await User.findById(decoded.id).select("-password");
    if (!user) {
      throw Errors.UNAUTHORIZED("User no longer exists");
    }

    req.user = user;
    next();
  } catch (error) {
    next(error);
  }
};
