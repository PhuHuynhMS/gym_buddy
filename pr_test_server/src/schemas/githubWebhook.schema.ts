import { z } from "zod";

export const supportedPullRequestActions = [
  "opened",
  "synchronize",
  "reopened",
] as const;

export const githubPullRequestWebhookSchema = z.object({
  action: z.string(),
  repository: z.object({
    full_name: z.string(),
  }),
  pull_request: z.object({
    number: z.number().int().positive(),
    head: z.object({
      sha: z.string(),
    }),
  }),
});

export type GitHubPullRequestWebhook = z.infer<
  typeof githubPullRequestWebhookSchema
>;

export const isSupportedPullRequestAction = (
  action: string,
): action is (typeof supportedPullRequestActions)[number] => {
  return supportedPullRequestActions.includes(
    action as (typeof supportedPullRequestActions)[number],
  );
};
