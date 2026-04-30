import { Errors } from "../utils/AppError";

let isRunning = false;

export const withRunLock = async <T>(task: () => Promise<T>): Promise<T> => {
  if (isRunning) {
    throw Errors.CONFLICT("Another PR test run is already in progress.");
  }

  isRunning = true;
  try {
    return await task();
  } finally {
    isRunning = false;
  }
};
