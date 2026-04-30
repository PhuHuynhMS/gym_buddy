import { execFile } from "node:child_process";
import path from "node:path";
import { promisify } from "node:util";
import { Errors } from "../utils/AppError";
import type { GitHubPullRequest } from "./githubClient";

const execFileAsync = promisify(execFile);

export interface GitCommandResult {
  command: string;
  stdout: string;
  stderr: string;
}

export interface ChangedFileContent {
  path: string;
  content: string;
  truncated: boolean;
}

const getRepoPath = () => {
  const configuredPath = process.env.TARGET_REPO_PATH;
  return configuredPath
    ? path.resolve(configuredPath)
    : path.resolve(process.cwd(), "..");
};

const runGit = async (
  args: string[],
  allowFailure = false,
): Promise<GitCommandResult> => {
  const command = `git ${args.join(" ")}`;
  try {
    const { stdout, stderr } = await execFileAsync("git", args, {
      cwd: getRepoPath(),
      maxBuffer: 1024 * 1024 * 10,
    });

    return { command, stdout, stderr };
  } catch (error) {
    const execError = error as NodeJS.ErrnoException & {
      stdout?: string;
      stderr?: string;
    };
    const result = {
      command,
      stdout: execError.stdout ?? "",
      stderr: execError.stderr ?? execError.message,
    };

    if (allowFailure) {
      return result;
    }

    throw Errors.INTERNAL("Git command failed.", result);
  }
};

export const prepareAndMergePullRequest = async (
  pr: GitHubPullRequest,
): Promise<GitCommandResult[]> => {
  const results: GitCommandResult[] = [];
  const prFetchRef = `pull/${pr.number}/head:refs/remotes/origin/pr/${pr.number}`;
  const prBranchRef = `refs/remotes/origin/pr/${pr.number}`;

  results.push(await runGit(["fetch", "origin", pr.baseRef]));
  results.push(await runGit(["checkout", pr.baseRef]));
  results.push(await runGit(["reset", "--hard", `origin/${pr.baseRef}`]));
  results.push(await runGit(["fetch", "origin", prFetchRef]));
  results.push(await runGit(["merge", "--no-edit", prBranchRef]));

  return results;
};

const getNumberEnv = (name: string, defaultValue: number): number => {
  const rawValue = process.env[name];
  if (!rawValue) {
    return defaultValue;
  }

  const value = Number(rawValue);
  return Number.isFinite(value) && value > 0 ? value : defaultValue;
};

const truncate = (value: string, maxChars: number) => {
  if (value.length <= maxChars) {
    return { value, truncated: false };
  }

  return {
    value: value.slice(0, maxChars),
    truncated: true,
  };
};

export const getPullRequestDiff = async (
  baseRef: string,
): Promise<{ diff: string; truncated: boolean }> => {
  const maxDiffChars = getNumberEnv("AI_REVIEW_MAX_DIFF_CHARS", 60000);
  const result = await runGit(["diff", "origin/" + baseRef + "...HEAD"]);
  const truncated = truncate(result.stdout, maxDiffChars);

  return {
    diff: truncated.value,
    truncated: truncated.truncated,
  };
};

export const getChangedFilesWithContent = async (
  baseRef: string,
): Promise<ChangedFileContent[]> => {
  const maxFiles = getNumberEnv("AI_REVIEW_MAX_FILES", 20);
  const maxFileChars = getNumberEnv("AI_REVIEW_MAX_FILE_CHARS", 20000);
  const result = await runGit([
    "diff",
    "--name-only",
    "--diff-filter=ACMRT",
    "origin/" + baseRef + "...HEAD",
  ]);
  const filePaths = result.stdout
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .slice(0, maxFiles);

  const files: ChangedFileContent[] = [];
  for (const filePath of filePaths) {
    const fileResult = await runGit(["show", "HEAD:" + filePath], true);
    if (fileResult.stderr) {
      files.push({
        path: filePath,
        content: `[Unable to read file content: ${fileResult.stderr}]`,
        truncated: false,
      });
      continue;
    }

    const truncated = truncate(fileResult.stdout, maxFileChars);
    files.push({
      path: filePath,
      content: truncated.value,
      truncated: truncated.truncated,
    });
  }

  return files;
};

export const cleanupWorkspace = async (
  baseRef: string,
): Promise<GitCommandResult[]> => {
  const results: GitCommandResult[] = [];

  results.push(await runGit(["merge", "--abort"], true));
  results.push(await runGit(["fetch", "origin", baseRef], true));
  results.push(await runGit(["checkout", baseRef], true));
  results.push(await runGit(["reset", "--hard", "origin/" + baseRef], true));

  return results;
};
