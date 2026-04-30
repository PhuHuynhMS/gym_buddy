import { createHmac, timingSafeEqual } from "node:crypto";
import { Errors } from "../utils/AppError";

const SIGNATURE_PREFIX = "sha256=";

export const verifyGitHubWebhookSignature = (
  payload: Buffer,
  signatureHeader: string | undefined,
): void => {
  const secret = process.env.GITHUB_WEBHOOK_SECRET;
  if (!secret) {
    throw Errors.INTERNAL("GITHUB_WEBHOOK_SECRET is not configured.");
  }

  if (!signatureHeader?.startsWith(SIGNATURE_PREFIX)) {
    throw Errors.UNAUTHORIZED("Missing or invalid GitHub webhook signature.");
  }

  const expectedSignature = `${SIGNATURE_PREFIX}${createHmac("sha256", secret)
    .update(payload)
    .digest("hex")}`;

  const provided = Buffer.from(signatureHeader, "utf8");
  const expected = Buffer.from(expectedSignature, "utf8");

  if (
    provided.length !== expected.length ||
    !timingSafeEqual(provided, expected)
  ) {
    throw Errors.UNAUTHORIZED("GitHub webhook signature mismatch.");
  }
};
