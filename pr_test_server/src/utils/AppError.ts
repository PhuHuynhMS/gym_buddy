export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly code: string,
    message: string,
    public readonly details?: unknown,
  ) {
    super(message);
    this.name = "AppError";
  }
}

export const Errors = {
  BAD_REQUEST: (message: string, details?: unknown) =>
    new AppError(400, "BAD_REQUEST", message, details),
  UNAUTHORIZED: (message: string, details?: unknown) =>
    new AppError(401, "UNAUTHORIZED", message, details),
  NOT_FOUND: (message: string, details?: unknown) =>
    new AppError(404, "NOT_FOUND", message, details),
  CONFLICT: (message: string, details?: unknown) =>
    new AppError(409, "CONFLICT", message, details),
  INTERNAL: (message: string, details?: unknown) =>
    new AppError(500, "INTERNAL_ERROR", message, details),
};
