import type { ChangedFileContent } from "../gitWorkspace";

export interface AiReviewInput {
  repo: string;
  prNumber: number;
  prTitle: string;
  baseRef: string;
  headSha: string;
  diff: string;
  diffTruncated: boolean;
  changedFiles: ChangedFileContent[];
}

export interface AiReviewResult {
  provider: string;
  model: string;
  reviewMarkdown: string;
}

export interface AiReviewProvider {
  readonly name: string;
  readonly model: string;
  review(input: AiReviewInput): Promise<AiReviewResult>;
}
