import express from "express";
import { handleGitHubWebhook } from "../controllers/githubWebhookController";

const router = express.Router();

router.post(
  "/github",
  express.raw({ type: "application/json" }),
  handleGitHubWebhook,
);

export default router;
