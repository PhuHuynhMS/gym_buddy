import type { GitHubPullRequest } from "./githubClient";
import {
  getChangedFilesWithContent,
  getPullRequestDiff,
} from "./gitWorkspace";
import { createAiReviewProvider } from "./aiReview/providerFactory";
import type { AiReviewResult } from "./aiReview/types";

export interface AiReviewRunResult {
  exitCode: number;
  output: string;
  provider: string;
  model: string;
}

export const runAiReview = async (
  repo: string,
  pr: GitHubPullRequest,
): Promise<AiReviewRunResult> => {
  const provider = createAiReviewProvider();
  const [{ diff, truncated: diffTruncated }, changedFiles] =
    await Promise.all([
      getPullRequestDiff(pr.baseRef),
      getChangedFilesWithContent(pr.baseRef),
    ]);

  const result: AiReviewResult = await provider.review({
    repo,
    prNumber: pr.number,
    prTitle: pr.title,
    baseRef: pr.baseRef,
    headSha: pr.headSha,
    diff,
    diffTruncated,
    changedFiles,
  });

  return {
    exitCode: 0,
    output: result.reviewMarkdown,
    provider: result.provider,
    model: result.model,
  };
};
