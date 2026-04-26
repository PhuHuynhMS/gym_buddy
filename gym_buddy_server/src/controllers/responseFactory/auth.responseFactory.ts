import { authResponseSchema, IAuthResponse } from "../../schemas/auth.schema";
import { IUser } from "../../models/User";

export const authResponseFactory = {
  create(user: IUser, token: string): IAuthResponse {
    return authResponseSchema.parse({
      id: user._id.toString(),
      username: user.username,
      email: user.email,
      token,
    });
  },
};
