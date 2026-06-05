import type { Request, Response, NextFunction } from "express";
import BuddyAvailability from "../models/BuddyAvailability";
import { nearbyQuerySchema } from "../schemas/maps.schema";

export async function getNearbyBuddies(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const parsed = nearbyQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message: "Invalid query parameters",
        details: { errors: parsed.error.flatten().fieldErrors },
      });
      return;
    }

    const { lat, lng, radius, limit, offset } = parsed.data;

    const results = await BuddyAvailability.aggregate([
      {
        $geoNear: {
          near: { type: "Point", coordinates: [lng, lat] },
          distanceField: "distanceKm",
          distanceMultiplier: 0.001,
          maxDistance: radius * 1000,
          spherical: true,
          query: {
            status: "active",
            availableUntil: { $gt: new Date() },
            visibility: "public",
          },
        },
      },
      { $skip: offset },
      { $limit: limit + 1 },
      { $project: { __v: 0 } },
    ]);

    const hasMore = results.length > limit;
    const data = hasMore ? results.slice(0, limit) : results;

    res.status(200).json({
      success: true,
      data,
      pagination: { limit, offset, hasMore },
    });
  } catch (err) {
    next(err);
  }
}
