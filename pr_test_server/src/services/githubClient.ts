import { Errors } from "../utils/AppError";

export interface GitHubPullRequest {
  number: number;
  title: string;
  htmlUrl: string;
  headRef: string;
  headSha: string;
  baseRef: string;
}

interface GitHubPrResponse {
  number: number;
  title: string;
  html_url: string;
  head: {
    ref: string;
    sha: string;
  };
  base: {
    ref: string;
  };
}

const getGitHubConfig = () => {
  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    throw Errors.INTERNAL("GITHUB_TOKEN is not configured.");
  }

  return {
    token,
    apiBaseUrl: process.env.GITHUB_API_BASE_URL ?? "https://api.github.com",
  };
};

const githubRequest = async <T>(
  path: string,
  options: RequestInit = {},
): Promise<T> => {
  const { token, apiBaseUrl } = getGitHubConfig();
  const response = await fetch(`${apiBaseUrl}${path}`, {
    ...options,
    headers: {
      Accept: "application/vnd.github+json",
      Authorization: `Bearer ${token}`,
      "User-Agent": "gym-buddy-pr-test-server",
      "X-GitHub-Api-Version": "2022-11-28",
      ...options.headers,
    },
  });

  if (!response.ok) {
    const errorBody = await response.text();
    const details = {
      status: response.status,
      path,
      body: errorBody,
    };

    if (response.status === 404) {
      throw Errors.NOT_FOUND(
        "GitHub resource not found. Check the repo name, PR number, and token access.",
        details,
      );
    }

    if (response.status === 401 || response.status === 403) {
      throw Errors.UNAUTHORIZED(
        "GitHub authentication failed. Check GITHUB_TOKEN permissions.",
        details,
      );
    }

    throw Errors.INTERNAL("GitHub API request failed.", {
      ...details,
    });
  }

  return (await response.json()) as T;
};

export const getPullRequest = async (
  repo: string,
  prNumber: number,
): Promise<GitHubPullRequest> => {
  const pr = await githubRequest<GitHubPrResponse>(
    `/repos/${repo}/pulls/${prNumber}`,
  );

  return {
    number: pr.number,
    title: pr.title,
    htmlUrl: pr.html_url,
    headRef: pr.head.ref,
    headSha: pr.head.sha,
    baseRef: pr.base.ref,
  };
};

export const createPullRequestComment = async (
  repo: string,
  prNumber: number,
  body: string,
): Promise<void> => {
  await githubRequest(`/repos/${repo}/issues/${prNumber}/comments`, {
    method: "POST",
    body: JSON.stringify({ body }),
  });
};
