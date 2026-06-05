import express, { Router } from "express";
import { getNearbyGyms } from "../controllers/gyms.controller";

const router: Router = express.Router();

router.get("/nearby", getNearbyGyms);

export default router;
