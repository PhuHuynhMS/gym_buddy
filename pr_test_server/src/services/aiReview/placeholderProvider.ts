import type { AiReviewInput, AiReviewProvider, AiReviewResult } from "./types";

export class PlaceholderAiReviewProvider implements AiReviewProvider {
  readonly name = "placeholder";
  readonly model = "placeholder";

  async review(input: AiReviewInput): Promise<AiReviewResult> {
    return {
      provider: this.name,
      model: this.model,
      reviewMarkdown: [
        "## AI Review",
        "",
        "### Summary",
        `- Placeholder review for PR #${input.prNumber}.`,
        "- AI provider is not enabled yet.",
        "",
        "### Findings",
        "- No blocking issues found.",
        "",
        "### Suggested Tests",
        "- Configure an AI provider to receive real review suggestions.",
        "",
        "### Note",
        "AI review only. No code was modified.",
      ].join("\n"),
    };
  }
}
