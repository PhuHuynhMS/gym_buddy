import bcrypt from "bcryptjs";

const SALT_ROUNDS = 10;

/**
 * Hash password using bcrypt
 * @param password - Plain text password
 * @returns Hashed password
 */
export const hashPassword = async (password: string): Promise<string> => {
  return await bcrypt.hash(password, SALT_ROUNDS);
};

/**
 * Compare plain text password with hashed password
 * @param password - Plain text password
 * @param hash - Hashed password to compare with
 * @returns True if password matches, false otherwise
 */
export const comparePassword = async (
  password: string,
  hash: string,
): Promise<boolean> => {
  return await bcrypt.compare(password, hash);
};
