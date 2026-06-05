import mongoose, { Document, Schema, Types } from "mongoose";
import type { IGeoPoint } from "./Gym";

export type BuddyAvailabilityStatus = "active" | "paused" | "expired";
export type BuddyAvailabilityVisibility = "public" | "matches_only";

export interface IBuddyAvailability extends Document {
  userId: Types.ObjectId;
  gymId?: Types.ObjectId;
  location: IGeoPoint;
  availableFrom: Date;
  availableUntil: Date;
  workoutTypes: string[];
  note?: string;
  visibility: BuddyAvailabilityVisibility;
  status: BuddyAvailabilityStatus;
  createdAt: Date;
  updatedAt: Date;
}

const GeoPointSchema = new Schema<IGeoPoint>(
  {
    type: { type: String, enum: ["Point"], required: true, default: "Point" },
    coordinates: {
      type: [Number],
      required: true,
      validate: {
        validator: (coordinates: number[]) => coordinates.length === 2,
        message: "Coordinates must be [longitude, latitude].",
      },
    },
  },
  { _id: false },
);

const BuddyAvailabilitySchema = new Schema<IBuddyAvailability>(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    gymId: { type: Schema.Types.ObjectId, ref: "Gym" },
    location: { type: GeoPointSchema, required: true },
    availableFrom: { type: Date, required: true },
    availableUntil: { type: Date, required: true },
    workoutTypes: { type: [String], default: [] },
    note: { type: String, trim: true, maxlength: 280 },
    visibility: {
      type: String,
      enum: ["public", "matches_only"],
      default: "public",
      required: true,
    },
    status: {
      type: String,
      enum: ["active", "paused", "expired"],
      default: "active",
      required: true,
    },
  },
  { timestamps: true },
);

BuddyAvailabilitySchema.index({ location: "2dsphere", status: 1, availableUntil: 1 });

export default mongoose.model<IBuddyAvailability>(
  "BuddyAvailability",
  BuddyAvailabilitySchema,
);
