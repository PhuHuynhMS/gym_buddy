import mongoose, { Document, Schema, Types } from "mongoose";

export type GymSource = "manual" | "imported" | "user_suggested";
export type GymVerificationStatus =
  | "unverified"
  | "pending"
  | "verified"
  | "rejected";

export interface IGeoPoint {
  type: "Point";
  coordinates: [number, number];
}

export interface IGym extends Document {
  name: string;
  address: string;
  location: IGeoPoint;
  phoneNumber?: string;
  websiteUrl?: string;
  amenities: string[];
  source: GymSource;
  verificationStatus: GymVerificationStatus;
  suggestedBy?: Types.ObjectId;
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

const GymSchema = new Schema<IGym>(
  {
    name: { type: String, required: true, trim: true, maxlength: 120 },
    address: { type: String, required: true, trim: true, maxlength: 240 },
    location: { type: GeoPointSchema, required: true },
    phoneNumber: { type: String, trim: true, maxlength: 32 },
    websiteUrl: { type: String, trim: true, maxlength: 240 },
    amenities: { type: [String], default: [] },
    source: {
      type: String,
      enum: ["manual", "imported", "user_suggested"],
      default: "manual",
      required: true,
    },
    verificationStatus: {
      type: String,
      enum: ["unverified", "pending", "verified", "rejected"],
      default: "unverified",
      required: true,
    },
    suggestedBy: { type: Schema.Types.ObjectId, ref: "User" },
  },
  { timestamps: true },
);

GymSchema.index({ location: "2dsphere" });

export default mongoose.model<IGym>("Gym", GymSchema);
