import express from "express";
import type { Request, Response } from "express";
import cors from "cors";
import connectDB from "./src/config/db";

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Connect Database
connectDB();

app.get("/", (req: Request, res: Response) => {
  res.send("GymBuddy API with TypeScript is running...");
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server started on port ${PORT}`));
