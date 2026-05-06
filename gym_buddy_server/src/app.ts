import cors from "cors";
import express from "express";
import type { Request, Response } from "express";
import authRoutes from "./routes/auth.routes";
import { errorMiddleware } from "./middlewares/errorMiddleware";

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (_req: Request, res: Response) => {
  res.send("GymBuddy API with TypeScript is running...");
});

app.use("/api/v1/auth", authRoutes);

app.use(errorMiddleware);

export default app;
