import mongoose, { Document, Schema, Types } from "mongoose";

export type SecurityEventType =
  | "refresh_reuse_detected"
  | "session_revoked"
  | "logout_all";

export interface ISecurityEvent {
  type: SecurityEventType;
  occurredAt: Date;
  metadata?: Record<string, unknown>;
}

export interface IAuthSession extends Document {
  userId: Types.ObjectId;
  refreshTokenHash: string;
  rotatedFromTokenHash?: string;
  expiresAt: Date;
  revokedAt?: Date;
  reuseDetectedAt?: Date;
  deviceName: string;
  platform: string;
  ipAddress: string;
  userAgent: string;
  lastUsedAt: Date;
  securityEvents: ISecurityEvent[];
  createdAt: Date;
  updatedAt: Date;
}

const SecurityEventSchema = new Schema<ISecurityEvent>(
  {
    type: {
      type: String,
      enum: ["refresh_reuse_detected", "session_revoked", "logout_all"],
      required: true,
    },
    occurredAt: { type: Date, required: true },
    metadata: { type: Schema.Types.Mixed },
  },
  { _id: false },
);

const AuthSessionSchema = new Schema<IAuthSession>(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    refreshTokenHash: { type: String, required: true, index: true },
    rotatedFromTokenHash: { type: String, index: true },
    expiresAt: { type: Date, required: true, index: true },
    revokedAt: { type: Date },
    reuseDetectedAt: { type: Date },
    deviceName: { type: String, required: true },
    platform: { type: String, required: true },
    ipAddress: { type: String, required: true },
    userAgent: { type: String, required: true },
    lastUsedAt: { type: Date, required: true },
    securityEvents: { type: [SecurityEventSchema], default: [] },
  },
  { timestamps: true },
);

AuthSessionSchema.index({ userId: 1, revokedAt: 1, expiresAt: 1 });

export default mongoose.model<IAuthSession>("AuthSession", AuthSessionSchema);
