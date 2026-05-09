import {
  authResponseSchema,
  IAuthResponse,
  IProfileResponse,
  ISessionsResponse,
  ITokenResponse,
  profileResponseSchema,
  sessionsResponseSchema,
  tokenResponseSchema,
} from "../../schemas/auth.schema";
import { IUser } from "../../models/User";
import { IAuthSession } from "../../models/AuthSession";

export const authResponseFactory = {
  create(
    user: IUser,
    accessToken: string,
    accessTokenExpiresAt: Date,
    sessionId: string,
    message: string,
  ): IAuthResponse {
    return authResponseSchema.parse({
      success: true,
      message,
      data: {
        user: {
          id: user._id.toString(),
          username: user.username,
          email: user.email,
        },
        accessToken,
        accessTokenExpiresAt: accessTokenExpiresAt.toISOString(),
        tokenType: "Bearer",
        sessionId,
      },
    });
  },

  token(
    accessToken: string,
    accessTokenExpiresAt: Date,
    sessionId: string,
    message: string,
  ): ITokenResponse {
    return tokenResponseSchema.parse({
      success: true,
      message,
      data: {
        accessToken,
        accessTokenExpiresAt: accessTokenExpiresAt.toISOString(),
        tokenType: "Bearer",
        sessionId,
      },
    });
  },

  profile(user: IUser, message: string): IProfileResponse {
    return profileResponseSchema.parse({
      success: true,
      message,
      data: {
        user: {
          id: user._id.toString(),
          username: user.username,
          email: user.email,
          avatar: user.avatar,
          fitnessLevel: user.fitnessLevel,
          fcmToken: user.fcmToken,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
        },
      },
    });
  },

  sessions(sessions: IAuthSession[], message: string): ISessionsResponse {
    return sessionsResponseSchema.parse({
      success: true,
      message,
      data: {
        sessions: sessions.map((session) => ({
          id: session._id.toString(),
          deviceName: session.deviceName,
          platform: session.platform,
          ipAddress: session.ipAddress,
          userAgent: session.userAgent,
          lastUsedAt: session.lastUsedAt.toISOString(),
          createdAt: session.createdAt.toISOString(),
          expiresAt: session.expiresAt.toISOString(),
        })),
      },
    });
  },
};
