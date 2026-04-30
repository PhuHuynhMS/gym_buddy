import express from "express";
import { triggerPrTest } from "../controllers/automationController";
import { validateRequest } from "../middlewares/validateRequest";
import { prTestRequestSchema } from "../schemas/automation.schema";

const router = express.Router();

router.post("/pr-test", validateRequest(prTestRequestSchema), triggerPrTest);

export default router;
