import type { AiReviewInput } from "./types";

const formatChangedFiles = (input: AiReviewInput): string => {
  if (input.changedFiles.length === 0) {
    return "No changed file contents were available.";
  }

  return input.changedFiles
    .map((file) => {
      const truncatedNote = file.truncated
        ? "\n[Content truncated because it exceeded the configured limit.]"
        : "";

      return [
        `### ${file.path}`,
        "",
        "```text",
        file.content,
        truncatedNote,
        "```",
      ].join("\n");
    })
    .join("\n\n");
};

export const buildAiReviewPrompt = (input: AiReviewInput): string => {
  const diffTruncatedNote = input.diffTruncated
    ? "\n[Diff truncated because it exceeded the configured limit.]"
    : "";

  return [
    "You are an AI code reviewer for a GitHub pull request.",
    "",
    "Hard rules:",
    "- Review only. Do not modify code.",
    "- Do not ask to create commits, branches, files, or patches.",
    "- Do not claim you ran tests.",
    "- Focus on correctness, regressions, security, data loss, edge cases, and missing tests.",
    "- If there are no clear issues, say so clearly.",
    "- Keep the review concise and actionable.",
    "",
    "Return Markdown in this exact structure:",
    "## AI Review",
    "",
    "### Summary",
    "- 1-3 bullets.",
    "",
    "### Findings",
    "- Use severity labels: High, Medium, Low.",
    "- Include file paths when relevant.",
    "- If no issues are found, write: No blocking issues found.",
    "",
    "### Suggested Tests",
    "- Mention tests that should be run or added.",
    "",
    "### Note",
    "AI review only. No code was modified.",
    "",
    "Pull request metadata:",
    `- Repository: ${input.repo}`,
    `- PR: #${input.prNumber} - ${input.prTitle}`,
    `- Base branch: ${input.baseRef}`,
    `- Head SHA: ${input.headSha}`,
    "",
    "PR diff:",
    "```diff",
    input.diff,
    diffTruncatedNote,
    "```",
    "",
    "Changed file contents:",
    formatChangedFiles(input),
  ].join("\n");
};
