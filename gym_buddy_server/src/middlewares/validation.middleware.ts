import { Request, Response, NextFunction } from "express";
import { ZodSchema } from "zod";

/**
 * Middleware validate request body with Zod schema
 * @param schema - Zod schema validate
 */
export const validateRequest = (schema: ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      const validatedData = schema.parse(req.body);
      req.body = validatedData;
      next();
    } catch (error) {
      next(error);
    }
  };
};
