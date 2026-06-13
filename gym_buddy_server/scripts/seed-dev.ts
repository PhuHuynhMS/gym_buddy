/**
 * Seed script for local dev — inserts gyms and buddy availabilities near HCMC.
 * Run: npx tsx scripts/seed-dev.ts
 */
import mongoose from "mongoose";
import Gym from "../src/models/Gym";
import BuddyAvailability from "../src/models/BuddyAvailability";
import User from "../src/models/User";

const MONGO_URI =
  process.env.MONGO_URI || "mongodb://127.0.0.1:27017/gym_buddy";

// Gyms spread across HCMC districts
const gyms = [
  // Quận 1
  { name: "California Fitness & Yoga Q1", address: "135 Hai Bà Trưng, Q1", location: { type: "Point" as const, coordinates: [106.6986, 10.7794] } },
  { name: "Fit24 Gym Q1", address: "72 Lê Thánh Tôn, Q1", location: { type: "Point" as const, coordinates: [106.7021, 10.7752] } },
  // Quận 3
  { name: "Snap Fitness Q3", address: "150 Pasteur, Q3", location: { type: "Point" as const, coordinates: [106.6923, 10.7831] } },
  // Quận 7
  { name: "Crunch Fitness Phú Mỹ Hưng", address: "Crescent Mall, Q7", location: { type: "Point" as const, coordinates: [106.7172, 10.7295] } },
  { name: "The New Gym Q7", address: "18 Nguyễn Thị Thập, Q7", location: { type: "Point" as const, coordinates: [106.7215, 10.7340] } },
  // Quận 10
  { name: "Elite Fitness Q10", address: "273 Lý Thường Kiệt, Q10", location: { type: "Point" as const, coordinates: [106.6680, 10.7731] } },
  // Bình Thạnh
  { name: "UFC Gym Bình Thạnh", address: "26 Ung Văn Khiêm, Bình Thạnh", location: { type: "Point" as const, coordinates: [106.7124, 10.8012] } },
  { name: "Iron Gym Bình Thạnh", address: "53 Ngô Tất Tố, Bình Thạnh", location: { type: "Point" as const, coordinates: [106.7098, 10.8045] } },
  // Gò Vấp
  { name: "Olympia Gym Gò Vấp", address: "12 Phan Văn Trị, Gò Vấp", location: { type: "Point" as const, coordinates: [106.6823, 10.8384] } },
  // Tân Bình
  { name: "World Gym Tân Bình", address: "Sân bay Tân Sơn Nhất, Tân Bình", location: { type: "Point" as const, coordinates: [106.6659, 10.8125] } },
  // Thủ Đức / TP Thủ Đức
  { name: "Viettel Fitness Thủ Đức", address: "Vincom Thủ Đức", location: { type: "Point" as const, coordinates: [106.7515, 10.8437] } },
  // Quận 2 / An Khánh
  { name: "California Fitness Q2", address: "Estella Place, Q2", location: { type: "Point" as const, coordinates: [106.7467, 10.7960] } },
  // Quận 5
  { name: "Strong Gym Q5", address: "190 Trần Hưng Đạo, Q5", location: { type: "Point" as const, coordinates: [106.6812, 10.7564] } },
  // Quận 12
  { name: "Power Gym Q12", address: "Tô Ký, Q12", location: { type: "Point" as const, coordinates: [106.6445, 10.8697] } },
  // Nhà Bè
  { name: "FitZone Nhà Bè", address: "Nguyễn Hữu Thọ, Nhà Bè", location: { type: "Point" as const, coordinates: [106.7012, 10.6921] } },
];

const workoutTypeOptions = [
  ["strength", "powerlifting"],
  ["cardio", "running"],
  ["yoga", "flexibility"],
  ["crossfit", "hiit"],
  ["swimming"],
  ["boxing", "muay thai"],
];

async function seed() {
  await mongoose.connect(MONGO_URI);
  console.log("Connected to MongoDB");

  // Clear existing dev data
  await Gym.deleteMany({});
  await BuddyAvailability.deleteMany({});
  console.log("Cleared existing gyms and buddy availabilities");

  // Insert gyms
  const insertedGyms = await Gym.insertMany(gyms);
  console.log(`Inserted ${insertedGyms.length} gyms`);

  // Get or create a seed user for buddies
  let seedUser = await User.findOne({ email: "seed@gymbuddy.dev" });
  if (!seedUser) {
    seedUser = await User.create({
      username: "seed_user",
      email: "seed@gymbuddy.dev",
      password: "not-a-real-hash",
    });
  }

  // Insert buddy availabilities — offset ~100m from each gym so markers don't overlap
  const OFFSET = 0.0009; // ~100 metres
  const now = new Date();
  const buddies = insertedGyms.map((gym, i) => {
    const [lng, lat] = gym.location.coordinates;
    return {
      userId: seedUser!._id,
      gymId: gym._id,
      location: {
        type: "Point" as const,
        coordinates: [lng + OFFSET, lat + OFFSET] as [number, number],
      },
      availableFrom: now,
      availableUntil: new Date(now.getTime() + 4 * 60 * 60 * 1000),
      workoutTypes: workoutTypeOptions[i % workoutTypeOptions.length],
      visibility: "public" as const,
      status: "active" as const,
    };
  });

  const insertedBuddies = await BuddyAvailability.insertMany(buddies);
  console.log(`Inserted ${insertedBuddies.length} buddy availabilities`);

  await mongoose.disconnect();
  console.log("Done. Re-open the Map tab in the app to see markers.");
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
