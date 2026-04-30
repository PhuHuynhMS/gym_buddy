import { config } from "dotenv";
import express from "express";
import automationRoutes from "./src/routes/automation.routes";
import { errorMiddleware } from "./src/middlewares/errorMiddleware";

const environmentToken = process.env.GITHUB_TOKEN;
config({ override: true });
if (environmentToken) {
  process.env.GITHUB_TOKEN = environmentToken;
}

const app = express();

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
