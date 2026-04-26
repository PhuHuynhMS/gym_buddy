export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly details?: unknown;
  public readonly isOperational: boolean;

  constructor(
    message: string,
    statusCode: number,
    code: string,
    isOperational = true,
    details?: unknown,
  ) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = isOperational;

    Error.captureStackTrace(this, this.constructor);
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

export const Errors = {
  BAD_REQUEST: (msg: string, details?: unknown) =>
    new AppError(msg, 400, "BAD_REQUEST", true, details),
  UNAUTHORIZED: (msg: string, details?: unknown) =>
    new AppError(msg, 401, "UNAUTHORIZED", true, details),
  FORBIDDEN: (msg: string, details?: unknown) =>
    new AppError(msg, 403, "FORBIDDEN", true, details),
  NOT_FOUND: (msg: string, details?: unknown) =>
    new AppError(msg, 404, "NOT_FOUND", true, details),
  CONFLICT: (msg: string, details?: unknown) =>
    new AppError(msg, 409, "CONFLICT", true, details),
  INTERNAL: (msg: string, details?: unknown) =>
    new AppError(msg, 500, "INTERNAL_ERROR", false, details),
} as const;
