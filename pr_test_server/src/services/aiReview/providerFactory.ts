import { Errors } from "../../utils/AppError";
import { OllamaAiReviewProvider } from "./ollamaProvider";
import { PlaceholderAiReviewProvider } from "./placeholderProvider";
import type { AiReviewProvider } from "./types";

export const createAiReviewProvider = (): AiReviewProvider => {
  const provider = process.env.AI_REVIEW_PROVIDER ?? "ollama";

  if (provider === "ollama") {
    return new OllamaAiReviewProvider();
  }

  if (provider === "placeholder") {
    return new PlaceholderAiReviewProvider();
  }

  throw Errors.BAD_REQUEST(`Unsupported AI_REVIEW_PROVIDER: ${provider}`);
};
