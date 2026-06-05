import express, { Router } from "express";
import { getNearbyBuddies } from "../controllers/buddies.controller";
import { protect } from "../middlewares/auth.middleware";

const router: Router = express.Router();

router.get("/nearby", protect, getNearbyBuddies);

export default router;
