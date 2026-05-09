import type { Request } from "express";
import { Types } from "mongoose";
import AuthSession, { IAuthSession } from "../models/AuthSession";
import { Errors } from "../utils/AppError";
import {
  generateRefreshToken,
  hashRefreshToken,
} from "../utils/refreshToken";
import { REFRESH_TOKEN_EXPIRES_IN_SECONDS } from "../utils/generateToken";

const MAX_ACTIVE_SESSIONS_PER_USER = 5;

export interface CreatedSession {
  session: IAuthSession;
  refreshToken: string;
}

export const createAuthSession = async (
  userId: string,
  req: Request,
): Promise<CreatedSession> => {
  const refreshToken = generateRefreshToken();
  const now = new Date();
  const expiresAt = new Date(
    now.getTime() + REFRESH_TOKEN_EXPIRES_IN_SECONDS * 1000,
  );

  const session = await AuthSession.create({
    userId: new Types.ObjectId(userId),
    refreshTokenHash: hashRefreshToken(refreshToken),
    expiresAt,
    deviceName: getDeviceName(req),
    platform: getDevicePlatform(req),
    ipAddress: req.ip ?? "",
    userAgent: req.get("user-agent") ?? "",
    lastUsedAt: now,
  });

  await enforceSessionLimit(userId);

  return { session, refreshToken };
};

export const rotateRefreshSession = async (
  refreshToken: string,
): Promise<CreatedSession> => {
  const now = new Date();
  const incomingHash = hashRefreshToken(refreshToken);
  const activeSession = await AuthSession.findOne({
    refreshTokenHash: incomingHash,
    revokedAt: { $exists: false },
    expiresAt: { $gt: now },
  });

  if (activeSession) {
    const nextRefreshToken = generateRefreshToken();
    activeSession.rotatedFromTokenHash = activeSession.refreshTokenHash;
    activeSession.refreshTokenHash = hashRefreshToken(nextRefreshToken);
    activeSession.lastUsedAt = now;
    await activeSession.save();
    return { session: activeSession, refreshToken: nextRefreshToken };
  }

  const reusedSession = await AuthSession.findOne({
    rotatedFromTokenHash: incomingHash,
    revokedAt: { $exists: false },
  });

  if (reusedSession) {
    reusedSession.revokedAt = now;
    reusedSession.reuseDetectedAt = now;
    reusedSession.securityEvents.push({
      type: "refresh_reuse_detected",
      occurredAt: now,
    });
    await reusedSession.save();
  }

  throw Errors.UNAUTHORIZED("Refresh token is invalid or expired");
};

export const revokeSession = async (
  userId: string,
  sessionId: string,
  eventType: "session_revoked" | "logout_all" = "session_revoked",
): Promise<IAuthSession> => {
  const session = await AuthSession.findOne({
    _id: sessionId,
    userId,
    revokedAt: { $exists: false },
  });

  if (!session) {
    throw Errors.NOT_FOUND("Session was not found");
  }

  session.revokedAt = new Date();
  session.securityEvents.push({
    type: eventType,
    occurredAt: session.revokedAt,
  });
  await session.save();

  return session;
};

export const revokeAllSessions = async (userId: string): Promise<void> => {
  const now = new Date();
  await AuthSession.updateMany(
    { userId, revokedAt: { $exists: false } },
    {
      $set: { revokedAt: now },
      $push: {
        securityEvents: { type: "logout_all", occurredAt: now },
      },
    },
  );
};

export const listActiveSessions = async (
  userId: string,
): Promise<IAuthSession[]> => {
  return AuthSession.find({
    userId,
    revokedAt: { $exists: false },
    expiresAt: { $gt: new Date() },
  }).sort({ lastUsedAt: -1 });
};

const enforceSessionLimit = async (userId: string): Promise<void> => {
  const activeSessions = await AuthSession.find({
    userId,
    revokedAt: { $exists: false },
    expiresAt: { $gt: new Date() },
  }).sort({ lastUsedAt: -1 });

  const overflow = activeSessions.slice(MAX_ACTIVE_SESSIONS_PER_USER);
  await Promise.all(
    overflow.map(async (session) => {
      session.revokedAt = new Date();
      session.securityEvents.push({
        type: "session_revoked",
        occurredAt: session.revokedAt,
        metadata: { reason: "session_limit_exceeded" },
      });
      await session.save();
    }),
  );
};

const getDeviceName = (req: Request): string => {
  const value = req.get("x-device-name");
  return value?.trim() || "Unknown device";
};

const getDevicePlatform = (req: Request): string => {
  const value = req.get("x-device-platform");
  return value?.trim() || "unknown";
};
