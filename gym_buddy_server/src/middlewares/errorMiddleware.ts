import { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";
import { AppError } from "../utils/AppError";

interface ErrorResponse {
  success: false;
  code: string;
  message: string;
  details?: unknown;
  stack?: string;
}

const IS_DEV = process.env.NODE_ENV === "development";

export const errorMiddleware = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void => {
  if (err instanceof AppError) {
    const body: ErrorResponse = {
      success: false,
      code: err.code,
      message: err.message,
      ...(err.details !== undefined && { details: err.details }),
      ...(IS_DEV && { stack: err.stack }),
    };
    res.status(err.statusCode).json(body);
    return;
  }

  if (err instanceof ZodError) {
    const errors: Record<string, string> = {};
    err.issues.forEach((issue) => {
      const path = issue.path.join(".");
      errors[path || "root"] = issue.message;
    });

    res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "Validation error",
      details: { errors },
    });
    return;
  }

  if (err.name === "ValidationError") {
    res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: err.message,
    });
    return;
  }

  if ((err as any).code === 11000) {
    const field = Object.keys((err as any).keyValue ?? {})[0] ?? "field";
    res.status(409).json({
      success: false,
      code: "CONFLICT",
      message: `${field} already exists.`,
      details: { field },
    });
    return;
  }

  if (err.name === "JsonWebTokenError") {
    res.status(401).json({
      success: false,
      code: "INVALID_TOKEN",
      message: "Token is invalid.",
    });
    return;
  }

  if (err.name === "TokenExpiredError") {
    res.status(401).json({
      success: false,
      code: "TOKEN_EXPIRED",
      message: "Token has expired.",
    });
    return;
  }

  console.error("UNHANDLED ERROR:", err);
  res.status(500).json({
    success: false,
    code: "INTERNAL_ERROR",
    message: IS_DEV ? err.message : "Server error, please try again.",
    ...(IS_DEV && { stack: err.stack }),
  });
};
