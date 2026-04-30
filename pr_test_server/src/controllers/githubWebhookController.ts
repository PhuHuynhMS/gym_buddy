import type { NextFunction, Request, Response } from "express";
import {
  githubPullRequestWebhookSchema,
  isSupportedPullRequestAction,
} from "../schemas/githubWebhook.schema";
import { runPrTest } from "../services/prTestService";
import { verifyGitHubWebhookSignature } from "../services/githubWebhookVerifier";
import { Errors } from "../utils/AppError";

export const handleGitHubWebhook = (
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  try {
    if (!Buffer.isBuffer(req.body)) {
      throw Errors.BAD_REQUEST("GitHub webhook body must be a raw buffer.");
    }

    verifyGitHubWebhookSignature(
      req.body,
      req.header("x-hub-signature-256"),
    );

    const eventName = req.header("x-github-event");
    if (eventName !== "pull_request") {
      res.status(200).json({
        success: true,
        status: "ignored",
        reason: "unsupported_event",
        event: eventName ?? null,
      });
      return;
    }

    const payload = githubPullRequestWebhookSchema.parse(
      JSON.parse(req.body.toString("utf8")),
    );

    if (!isSupportedPullRequestAction(payload.action)) {
      res.status(200).json({
        success: true,
        status: "ignored",
        reason: "unsupported_action",
        action: payload.action,
      });
      return;
    }

    const repo = payload.repository.full_name;
    const prNumber = payload.pull_request.number;

    void runPrTest({ repo, prNumber }).catch((error) => {
      console.error("Background PR test run failed:", {
        repo,
        prNumber,
        error,
      });
    });

    res.status(202).json({
      success: true,
      status: "accepted",
      repo,
      prNumber,
      action: payload.action,
      headSha: payload.pull_request.head.sha,
    });
  } catch (error) {
    next(error);
  }
};
