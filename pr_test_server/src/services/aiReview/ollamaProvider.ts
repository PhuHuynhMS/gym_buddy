import { Errors } from "../../utils/AppError";
import { buildAiReviewPrompt } from "./promptBuilder";
import type { AiReviewInput, AiReviewProvider, AiReviewResult } from "./types";

interface OllamaGenerateResponse {
  response?: string;
  error?: string;
}

const trimTrailingSlash = (value: string) => value.replace(/\/+$/, "");

export class OllamaAiReviewProvider implements AiReviewProvider {
  readonly name = "ollama";
  readonly model = process.env.OLLAMA_MODEL ?? "qwen2.5-coder:7b";

  private readonly baseUrl = trimTrailingSlash(
    process.env.OLLAMA_BASE_URL ?? "http://localhost:11434",
  );

  async review(input: AiReviewInput): Promise<AiReviewResult> {
    const response = await fetch(`${this.baseUrl}/api/generate`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: this.model,
        prompt: buildAiReviewPrompt(input),
        stream: false,
        options: {
          temperature: 0.2,
        },
      }),
    });

    if (!response.ok) {
      throw Errors.INTERNAL("Ollama review request failed.", {
        status: response.status,
        body: await response.text(),
      });
    }

    const body = (await response.json()) as OllamaGenerateResponse;
    if (body.error) {
      throw Errors.INTERNAL("Ollama returned an error.", {
        error: body.error,
      });
    }

    const reviewMarkdown = body.response?.trim();
    if (!reviewMarkdown) {
      throw Errors.INTERNAL("Ollama returned an empty review.");
    }

    return {
      provider: this.name,
      model: this.model,
      reviewMarkdown,
    };
  }
}
