import mongoose, { Schema, Document } from "mongoose";

// Định nghĩa Interface cho User
export interface IUser extends Document {
  username: string;
  email: string;
  password?: string; // Dấu ? vì đôi khi chúng ta không muốn lấy password ra
  avatar: string;
  location: {
    type: string;
    coordinates: [number, number];
  };
  fitnessLevel: "Beginner" | "Intermediate" | "Advanced";
  fcmToken: string;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema: Schema = new Schema(
  {
    username: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    avatar: { type: String, default: "" },
    location: {
      type: { type: String, enum: ["Point"], default: "Point" },
      coordinates: { type: [Number], default: [0, 0] },
    },
    fitnessLevel: {
      type: String,
      enum: ["Beginner", "Intermediate", "Advanced"],
      default: "Beginner",
    },
    fcmToken: { type: String, default: "" },
  },
  { timestamps: true },
);

// Tạo Index cho Geospatial
UserSchema.index({ location: "2dsphere" });

export default mongoose.model<IUser>("User", UserSchema);
