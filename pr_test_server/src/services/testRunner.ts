export interface TestRunResult {
  exitCode: number;
  output: string;
}

export const runPlaceholderTest = async (): Promise<TestRunResult> => {
  return {
    exitCode: 0,
    output: "AI test placeholder passed",
  };
};
