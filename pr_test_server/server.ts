import { config } from "dotenv";
import express from "express";
import automationRoutes from "./src/routes/automation.routes";
import webhookRoutes from "./src/routes/webhook.routes";
import { errorMiddleware } from "./src/middlewares/errorMiddleware";

const environmentToken = process.env.GITHUB_TOKEN;
const environmentWebhookSecret = process.env.GITHUB_WEBHOOK_SECRET;
config({ override: true });
if (environmentToken) {
  process.env.GITHUB_TOKEN = environmentToken;
}
if (environmentWebhookSecret) {
  process.env.GITHUB_WEBHOOK_SECRET = environmentWebhookSecret;
}

const app = express();

app.use("/webhooks", webhookRoutes);
app.use(express.json());

app.get("/", (_req, res) => {
  res.json({
    success: true,
    message: "PR test automation server is running.",
  });
});

app.use("/automation", automationRoutes);

app.use(errorMiddleware);

const PORT = process.env.PORT ?? 5050;

app.listen(PORT, () => {
  console.log(`PR test automation server started on port ${PORT}`);
});
