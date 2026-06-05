import request from "supertest";
import { describe, expect, it } from "vitest";
import app from "../app";
import BuddyAvailability from "../models/BuddyAvailability";
import User from "../models/User";
import { generateToken } from "../utils/generateToken";
import { hashPassword } from "../utils/password";
import "../test/setup";

const CENTER = { lat: 10.762, lng: 106.660 };

const FUTURE = new Date(Date.now() + 2 * 60 * 60 * 1000); // +2 hours
const PAST = new Date(Date.now() - 60 * 60 * 1000);       // -1 hour

async function createUser() {
  return User.create({
    username: `user_${Math.random().toString(36).slice(2, 8)}`,
    email: `u_${Math.random().toString(36).slice(2, 8)}@test.com`,
    password: await hashPassword("pass123"),
  });
}

async function createAvailability(overrides: Partial<{
  coordinates: [number, number];
  status: string;
  visibility: string;
  availableUntil: Date;
  userId: string;
}> = {}, userId: string) {
  return BuddyAvailability.create({
    userId,
    location: {
      type: "Point",
      coordinates: overrides.coordinates ?? [106.661, 10.763],
    },
    availableFrom: new Date(),
    availableUntil: overrides.availableUntil ?? FUTURE,
    workoutTypes: ["strength"],
    visibility: overrides.visibility ?? "public",
    status: overrides.status ?? "active",
  });
}

describe("GET /api/v1/buddies/nearby", () => {
  it("returns 401 when Authorization header is missing", async () => {
    const res = await request(app)
      .get("/api/v1/buddies/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it("returns 401 when token is invalid", async () => {
    const res = await request(app)
      .get("/api/v1/buddies/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng })
      .set("Authorization", "Bearer not-a-token");

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it("returns 400 when lat is missing", async () => {
    const user = await createUser();
    const token = generateToken(user._id.toString());

    const res = await request(app)
      .get("/api/v1/buddies/nearby")
      .query({ lng: CENTER.lng })
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("returns 400 when radius exceeds 20 km", async () => {
    const user = await createUser();
    const token = generateToken(user._id.toString());

    const res = await request(app)
      .get("/api/v1/buddies/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng, radius: 50 })
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("returns 200 with empty data when no availability exists", async () => {
    const user = await createUser();
    const token = generateToken(user._id.toString());

    const res = await request(app)
      .get("/api/v1/buddies/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng })
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toEqual([]);
  });

  it("returns results sorted by distanceKm ascending", async () => {
    const user = await createUser();
    const token = generateToken(user._id.toString());

    await createAvailability({ coordinates: [106.700, 10.776] }, user._id.toString()); // far
    await createAvailability({ coordinates: [106.661, 10.763] }, user._id.toString()); // near

    const res = await request(app)
      .get("/api/v1/buddies/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng })
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(2);
    expect(res.body.data[0].distanceKm).toBeLessThan(res.body.data[1].distanceKm);
  });

  it("excludes paused availability", async () => {
    const user = await createUser();
    const token = generateToken(user._id.toString());

    await createAvailability({ status: "active" }, user._id.toString());
    await createAvailability({ status: "paused" }, user._id.toString());

    const res = await request(app)
      .get("/api/v1/buddies/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng })
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].status).toBe("active");
  });

  it("excludes expired availability (availableUntil in the past)", async () => {
    const user = await createUser();
    const token = generateToken(user._id.toString());

    await createAvailability({ availableUntil: FUTURE }, user._id.toString());
    await createAvailability({ availableUntil: PAST }, user._id.toString());

    const res = await request(app)
      .get("/api/v1/buddies/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng })
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
  });

  it("excludes matches_only availability", async () => {
    const user = await createUser();
    const token = generateToken(user._id.toString());

    await createAvailability({ visibility: "public" }, user._id.toString());
    await createAvailability({ visibility: "matches_only" }, user._id.toString());

    const res = await request(app)
      .get("/api/v1/buddies/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng })
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].visibility).toBe("public");
  });

  it("respects offset pagination", async () => {
    const user = await createUser();
    const token = generateToken(user._id.toString());

    await createAvailability({ coordinates: [106.661, 10.763] }, user._id.toString());
    await createAvailability({ coordinates: [106.670, 10.770] }, user._id.toString());

    const page1 = await request(app)
      .get("/api/v1/buddies/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng, limit: 1, offset: 0 })
      .set("Authorization", `Bearer ${token}`);

    const page2 = await request(app)
      .get("/api/v1/buddies/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng, limit: 1, offset: 1 })
      .set("Authorization", `Bearer ${token}`);

    expect(page1.body.data).toHaveLength(1);
    expect(page2.body.data).toHaveLength(1);
    expect(page1.body.data[0]._id).not.toBe(page2.body.data[0]._id);
    expect(page1.body.pagination.hasMore).toBe(true);
  });

  it("response items include distanceKm field", async () => {
    const user = await createUser();
    const token = generateToken(user._id.toString());

    await createAvailability({}, user._id.toString());

    const res = await request(app)
      .get("/api/v1/buddies/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng })
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(typeof res.body.data[0].distanceKm).toBe("number");
  });
});
