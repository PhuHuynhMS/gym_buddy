import {
  authResponseSchema,
  IAuthResponse,
  IProfileResponse,
  profileResponseSchema,
} from "../../schemas/auth.schema";
import { IUser } from "../../models/User";
import { AUTH_TOKEN_EXPIRES_IN } from "../../utils/generateToken";

export const authResponseFactory = {
  create(user: IUser, token: string, message: string): IAuthResponse {
    return authResponseSchema.parse({
      success: true,
      message,
      data: {
        user: {
          id: user._id.toString(),
          username: user.username,
          email: user.email,
        },
        token,
        tokenType: "Bearer",
        expiresIn: AUTH_TOKEN_EXPIRES_IN,
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
};
