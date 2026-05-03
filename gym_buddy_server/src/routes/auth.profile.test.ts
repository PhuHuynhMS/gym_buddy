import request from "supertest";
import { describe, expect, it } from "vitest";
import app from "../app";
import User from "../models/User";
import { generateToken } from "../utils/generateToken";
import { hashPassword } from "../utils/password";
import "../test/setup";

describe("GET /api/v1/auth/profile", () => {
  it("returns 401 when authorization header is missing", async () => {
    const response = await request(app).get("/api/v1/auth/profile");

    expect(response.status).toBe(401);
    expect(response.body).toMatchObject({
      success: false,
      code: "UNAUTHORIZED",
    });
  });

  it("returns 401 when token is invalid", async () => {
    const response = await request(app)
      .get("/api/v1/auth/profile")
      .set("Authorization", "Bearer not-a-real-token");

    expect(response.status).toBe(401);
    expect(response.body.success).toBe(false);
  });

  it("returns the current user profile without password", async () => {
    const user = await User.create({
      username: "tester",
      email: "tester@example.com",
      password: await hashPassword("secret123"),
      avatar: "https://example.com/avatar.png",
      fitnessLevel: "Intermediate",
      fcmToken: "test-fcm-token",
    });
    const token = generateToken(user._id.toString());

    const response = await request(app)
      .get("/api/v1/auth/profile")
      .set("Authorization", `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({
      success: true,
      message: "Profile fetched successfully",
      data: {
        user: {
          id: user._id.toString(),
          username: "tester",
          email: "tester@example.com",
          avatar: "https://example.com/avatar.png",
          fitnessLevel: "Intermediate",
          fcmToken: "test-fcm-token",
        },
      },
    });
    expect(response.body.data.user.password).toBeUndefined();
  });
});
