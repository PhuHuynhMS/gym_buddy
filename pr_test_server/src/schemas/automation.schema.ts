import { z } from "zod";

export const prTestRequestSchema = z.object({
  repo: z.string().regex(/^[^/\s]+\/[^/\s]+$/, {
    message: "repo must use owner/name format",
  }),
  prNumber: z.number().int().positive(),
});

export type PrTestRequest = z.infer<typeof prTestRequestSchema>;
