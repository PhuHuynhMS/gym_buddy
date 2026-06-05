import request from "supertest";
import { describe, expect, it } from "vitest";
import app from "../app";
import Gym from "../models/Gym";
import "../test/setup";

const CENTER = { lat: 10.762, lng: 106.660 };

async function createGym(overrides: Partial<{
  name: string;
  coordinates: [number, number];
  verificationStatus: string;
}> = {}) {
  return Gym.create({
    name: overrides.name ?? "Test Gym",
    address: "123 Test St",
    location: {
      type: "Point",
      coordinates: overrides.coordinates ?? [106.661, 10.763],
    },
    source: "manual",
    verificationStatus: overrides.verificationStatus ?? "unverified",
    amenities: [],
  });
}

describe("GET /api/v1/gyms/nearby", () => {
  it("returns 400 when lat is missing", async () => {
    const res = await request(app)
      .get("/api/v1/gyms/nearby")
      .query({ lng: CENTER.lng });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("returns 400 when lng is missing", async () => {
    const res = await request(app)
      .get("/api/v1/gyms/nearby")
      .query({ lat: CENTER.lat });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("returns 400 when radius exceeds 20 km", async () => {
    const res = await request(app)
      .get("/api/v1/gyms/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng, radius: 25 });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("returns 200 with empty data when no gyms exist", async () => {
    const res = await request(app)
      .get("/api/v1/gyms/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toEqual([]);
    expect(res.body.pagination).toBeDefined();
  });

  it("returns gyms sorted by distanceKm ascending", async () => {
    // far gym: ~4.4 km from center
    await createGym({ name: "Far Gym", coordinates: [106.700, 10.776] });
    // near gym: ~0.15 km from center
    await createGym({ name: "Near Gym", coordinates: [106.661, 10.763] });

    const res = await request(app)
      .get("/api/v1/gyms/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng });

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(2);
    expect(res.body.data[0].name).toBe("Near Gym");
    expect(res.body.data[1].name).toBe("Far Gym");
    expect(res.body.data[0].distanceKm).toBeLessThan(res.body.data[1].distanceKm);
  });

  it("excludes gyms with verificationStatus rejected", async () => {
    await createGym({ name: "Active Gym", verificationStatus: "verified" });
    await createGym({ name: "Rejected Gym", verificationStatus: "rejected" });

    const res = await request(app)
      .get("/api/v1/gyms/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng });

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].name).toBe("Active Gym");
  });

  it("excludes gyms outside the radius", async () => {
    await createGym({ name: "Nearby Gym", coordinates: [106.661, 10.763] });
    // ~37 km away — outside 5 km default
    await createGym({ name: "Distant Gym", coordinates: [107.000, 10.762] });

    const res = await request(app)
      .get("/api/v1/gyms/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng });

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].name).toBe("Nearby Gym");
  });

  it("respects offset pagination", async () => {
    await createGym({ name: "Gym A", coordinates: [106.661, 10.763] });
    await createGym({ name: "Gym B", coordinates: [106.670, 10.770] });

    const page1 = await request(app)
      .get("/api/v1/gyms/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng, limit: 1, offset: 0 });

    const page2 = await request(app)
      .get("/api/v1/gyms/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng, limit: 1, offset: 1 });

    expect(page1.body.data).toHaveLength(1);
    expect(page2.body.data).toHaveLength(1);
    expect(page1.body.data[0].name).not.toBe(page2.body.data[0].name);
    expect(page1.body.pagination.hasMore).toBe(true);
  });

  it("response items include distanceKm field", async () => {
    await createGym({ name: "Some Gym" });

    const res = await request(app)
      .get("/api/v1/gyms/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng });

    expect(res.status).toBe(200);
    expect(typeof res.body.data[0].distanceKm).toBe("number");
  });

  it("does not expose __v in response items", async () => {
    await createGym({ name: "Some Gym" });

    const res = await request(app)
      .get("/api/v1/gyms/nearby")
      .query({ lat: CENTER.lat, lng: CENTER.lng });

    expect(res.body.data[0].__v).toBeUndefined();
  });
});
