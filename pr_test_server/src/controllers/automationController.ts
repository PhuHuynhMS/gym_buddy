import type { NextFunction, Request, Response } from "express";
import type { PrTestRequest } from "../schemas/automation.schema";
import { runPrTest } from "../services/prTestService";

export const triggerPrTest = async (
  req: Request<unknown, unknown, PrTestRequest>,
  res: Response,
  next: NextFunction,
) => {
  try {
    const result = await runPrTest(req.body);

    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
};
