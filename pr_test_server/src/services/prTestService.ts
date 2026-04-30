import type { PrTestRequest } from "../schemas/automation.schema";
import { Errors } from "../utils/AppError";
import {
  createPullRequestComment,
  getPullRequest,
  type GitHubPullRequest,
} from "./githubClient";
import { cleanupWorkspace, prepareAndMergePullRequest } from "./gitWorkspace";
import { withRunLock } from "./runLock";
import { runPlaceholderTest } from "./testRunner";

export interface PrTestResult {
  repo: string;
  prNumber: number;
  baseRef: string;
  headSha: string;
  status: "passed";
  output: string;
}

const buildSuccessComment = (
  pr: GitHubPullRequest,
  output: string,
): string => {
  return [
    "## PR Test Automation Result",
    "",
    `Status: passed`,
    `PR: #${pr.number} - ${pr.title}`,
    `Base branch: ${pr.baseRef}`,
    `Head SHA: ${pr.headSha}`,
    "",
    "```text",
    output,
    "```",
  ].join("\n");
};

const buildFailureComment = (
  prNumber: number,
  error: unknown,
): string => {
  const message = error instanceof Error ? error.message : "Unknown error";
  const details =
    error instanceof Error && "details" in error
      ? JSON.stringify((error as { details?: unknown }).details, null, 2)
      : undefined;

  return [
    "## PR Test Automation Result",
    "",
    "Status: failed",
    `PR: #${prNumber}`,
    "",
    "```text",
    message,
    details ? `\n${details}` : "",
    "```",
  ].join("\n");
};

export const runPrTest = async (
  request: PrTestRequest,
): Promise<PrTestResult> => {
  return withRunLock(async () => {
    let pr: GitHubPullRequest | undefined;

    try {
      pr = await getPullRequest(request.repo, request.prNumber);

      await prepareAndMergePullRequest(pr);
      const testResult = await runPlaceholderTest();

      if (testResult.exitCode !== 0) {
        throw Errors.INTERNAL("Placeholder test failed.", testResult);
      }

      await createPullRequestComment(
        request.repo,
        request.prNumber,
        buildSuccessComment(pr, testResult.output),
      );

      return {
        repo: request.repo,
        prNumber: request.prNumber,
        baseRef: pr.baseRef,
        headSha: pr.headSha,
        status: "passed",
        output: testResult.output,
      };
    } catch (error) {
      await createPullRequestComment(
        request.repo,
        request.prNumber,
        buildFailureComment(request.prNumber, error),
      ).catch((commentError) => {
        console.error("Failed to comment PR error:", commentError);
      });

      throw error;
    } finally {
      if (pr) {
        await cleanupWorkspace(pr.baseRef).catch((cleanupError) => {
          console.error("Failed to cleanup git workspace:", cleanupError);
        });
      }
    }
  });
};
