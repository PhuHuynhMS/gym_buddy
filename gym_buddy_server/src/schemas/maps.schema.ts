import { z } from "zod";

export const geoPointSchema = z.object({
  type: z.literal("Point"),
  coordinates: z
    .tuple([z.number(), z.number()])
    .describe("[longitude, latitude]"),
});

export const gymSourceSchema = z.enum([
  "manual",
  "imported",
  "user_suggested",
]);

export const gymVerificationStatusSchema = z.enum([
  "unverified",
  "pending",
  "verified",
  "rejected",
]);

export const gymSchema = z.object({
  id: z.string(),
  name: z.string(),
  address: z.string(),
  location: geoPointSchema,
  phoneNumber: z.string().optional(),
  websiteUrl: z.string().optional(),
  amenities: z.array(z.string()),
  source: gymSourceSchema,
  verificationStatus: gymVerificationStatusSchema,
});

export const buddyAvailabilityStatusSchema = z.enum([
  "active",
  "paused",
  "expired",
]);

export const buddyAvailabilityVisibilitySchema = z.enum([
  "public",
  "matches_only",
]);

export const buddyAvailabilitySchema = z.object({
  id: z.string(),
  userId: z.string(),
  gymId: z.string().optional(),
  location: geoPointSchema,
  availableFrom: z.iso.datetime(),
  availableUntil: z.iso.datetime(),
  workoutTypes: z.array(z.string()),
  note: z.string().optional(),
  visibility: buddyAvailabilityVisibilitySchema,
  status: buddyAvailabilityStatusSchema,
});

export const nearbyQuerySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  lng: z.coerce.number().min(-180).max(180),
  radius: z.coerce.number().min(0.1).max(20).default(5),
  limit: z.coerce.number().int().min(1).max(50).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

export type GeoPoint = z.infer<typeof geoPointSchema>;
export type Gym = z.infer<typeof gymSchema>;
export type BuddyAvailability = z.infer<typeof buddyAvailabilitySchema>;
export type NearbyQuery = z.infer<typeof nearbyQuerySchema>;
