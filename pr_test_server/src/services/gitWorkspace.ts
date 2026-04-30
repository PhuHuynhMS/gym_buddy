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

export const cleanupWorkspace = async (
  baseRef: string,
): Promise<GitCommandResult[]> => {
  const results: GitCommandResult[] = [];

  results.push(await runGit(["merge", "--abort"], true));
  results.push(await runGit(["fetch", "origin", baseRef], true));
  results.push(await runGit(["checkout", baseRef], true));
  results.push(await runGit(["reset", "--hard", `origin/${baseRef}`], true));

  return results;
};
