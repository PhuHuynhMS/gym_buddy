import type { ErrorRequestHandler } from "express";
import { ZodError } from "zod";
import { AppError } from "../utils/AppError";

const IS_DEV = process.env.NODE_ENV === "development";

export const errorMiddleware: ErrorRequestHandler = (err, _req, res, _next) => {
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      code: err.code,
      message: err.message,
      ...(err.details !== undefined && { details: err.details }),
      ...(IS_DEV && { stack: err.stack }),
    });
    return;
  }

  if (err instanceof ZodError) {
    const errors: Record<string, string> = {};
    err.issues.forEach((issue) => {
      errors[issue.path.join(".") || "root"] = issue.message;
    });

    res.status(400).json({
      success: false,
      code: "VALIDATION_ERROR",
      message: "Validation error",
      details: { errors },
    });
    return;
  }

  console.error("UNHANDLED ERROR:", err);
  res.status(500).json({
    success: false,
    code: "INTERNAL_ERROR",
    message: IS_DEV && err instanceof Error ? err.message : "Server error.",
    ...(IS_DEV && err instanceof Error && { stack: err.stack }),
  });
};
