import crypto from "crypto";
import type { Request, Response } from "express";
import { REFRESH_TOKEN_EXPIRES_IN_SECONDS } from "./generateToken";

export const REFRESH_TOKEN_COOKIE_NAME = "gym_buddy_refresh";
export const REFRESH_TOKEN_COOKIE_PATH = "/api/v1/auth";

export const generateRefreshToken = (): string =>
  crypto.randomBytes(48).toString("base64url");

export const hashRefreshToken = (token: string): string =>
  crypto.createHash("sha256").update(token).digest("hex");

export const getRefreshTokenFromCookie = (req: Request): string | undefined => {
  const cookieHeader = req.headers.cookie;
  if (!cookieHeader) {
    return undefined;
  }

  const cookies = cookieHeader.split(";").map((cookie) => cookie.trim());
  const refreshCookie = cookies.find((cookie) =>
    cookie.startsWith(`${REFRESH_TOKEN_COOKIE_NAME}=`),
  );

  if (!refreshCookie) {
    return undefined;
  }

  return decodeURIComponent(refreshCookie.split("=").slice(1).join("="));
};

export const setRefreshTokenCookie = (res: Response, token: string): void => {
  res.setHeader(
    "Set-Cookie",
    [
      `${REFRESH_TOKEN_COOKIE_NAME}=${encodeURIComponent(token)}`,
      "HttpOnly",
      "Secure",
      "SameSite=Strict",
      `Path=${REFRESH_TOKEN_COOKIE_PATH}`,
      `Max-Age=${REFRESH_TOKEN_EXPIRES_IN_SECONDS}`,
    ].join("; "),
  );
};

export const clearRefreshTokenCookie = (res: Response): void => {
  res.setHeader(
    "Set-Cookie",
    [
      `${REFRESH_TOKEN_COOKIE_NAME}=`,
      "HttpOnly",
      "Secure",
      "SameSite=Strict",
      `Path=${REFRESH_TOKEN_COOKIE_PATH}`,
      "Max-Age=0",
    ].join("; "),
  );
};
