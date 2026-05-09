import { NextFunction, Request, Response } from "express";
import User from "../models/User";
import { generateAccessToken } from "../utils/generateToken";
import { authResponseFactory } from "./responseFactory/auth.responseFactory";
import { hashPassword, comparePassword } from "../utils/password";
import { Errors } from "../utils/AppError";
import {
  clearRefreshTokenCookie,
  getRefreshTokenFromCookie,
  setRefreshTokenCookie,
} from "../utils/refreshToken";
import {
  createAuthSession,
  listActiveSessions,
  revokeAllSessions,
  revokeSession,
  rotateRefreshSession,
} from "../services/authSession.service";

export const register = async (
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  try {
    // Validation handled by validateRequest middleware
    const { username, email, password } = req.body;

    // Check if user already exists
    const userExists = await User.findOne({ email });
    if (userExists) {
      throw Errors.CONFLICT("User email already exists");
    }

    // Hash password before saving to database
    const hashedPassword = await hashPassword(password);

    // Create new user
    const user = await User.create({
      username,
      email,
      password: hashedPassword,
    });

    if (!user) {
      throw Errors.INTERNAL("Failed to create user");
    }

    const { session, refreshToken } = await createAuthSession(
      user._id.toString(),
      req,
    );
    const { token, expiresAt } = generateAccessToken(
      user._id.toString(),
      session._id.toString(),
    );
    const registerResponse = authResponseFactory.create(
      user,
      token,
      expiresAt,
      session._id.toString(),
      "Register successful",
    );

    setRefreshTokenCookie(res, refreshToken);
    res.status(201).json(registerResponse);
  } catch (error) {
    next(error);
  }
};

export const login = async (
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  try {
    // Validation handled by middleware validateRequest
    const { email, password } = req.body;

    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      throw Errors.UNAUTHORIZED("Email or password is incorrect");
    }

    // Compare password with hashed password
    const isPasswordValid = await comparePassword(password, user.password!);
    if (!isPasswordValid) {
      throw Errors.UNAUTHORIZED("Email or password is incorrect");
    }

    const { session, refreshToken } = await createAuthSession(
      user._id.toString(),
      req,
    );
    const { token, expiresAt } = generateAccessToken(
      user._id.toString(),
      session._id.toString(),
    );
    const loginResponse = authResponseFactory.create(
      user,
      token,
      expiresAt,
      session._id.toString(),
      "Login successful",
    );

    setRefreshTokenCookie(res, refreshToken);
    res.json(loginResponse);
  } catch (error) {
    next(error);
  }
};

export const refresh = async (
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  try {
    const refreshToken = getRefreshTokenFromCookie(req);
    if (!refreshToken) {
      throw Errors.UNAUTHORIZED("Refresh token is required");
    }

    const { session, refreshToken: nextRefreshToken } =
      await rotateRefreshSession(refreshToken);
    const { token, expiresAt } = generateAccessToken(
      session.userId.toString(),
      session._id.toString(),
    );

    setRefreshTokenCookie(res, nextRefreshToken);
    res.json(
      authResponseFactory.token(
        token,
        expiresAt,
        session._id.toString(),
        "Token refreshed",
      ),
    );
  } catch (error) {
    clearRefreshTokenCookie(res);
    next(error);
  }
};

export const logout = async (
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  try {
    if (!req.user || !req.sessionId) {
      throw Errors.UNAUTHORIZED("Authentication is required");
    }

    await revokeSession(req.user._id.toString(), req.sessionId);
    clearRefreshTokenCookie(res);
    res.json({ success: true, message: "Logged out successfully" });
  } catch (error) {
    next(error);
  }
};

export const logoutAll = async (
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  try {
    if (!req.user) {
      throw Errors.UNAUTHORIZED("Authentication is required");
    }

    await revokeAllSessions(req.user._id.toString());
    clearRefreshTokenCookie(res);
    res.json({ success: true, message: "Logged out from all devices" });
  } catch (error) {
    next(error);
  }
};

export const listSessions = async (
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  try {
    if (!req.user) {
      throw Errors.UNAUTHORIZED("Authentication is required");
    }

    const sessions = await listActiveSessions(req.user._id.toString());
    res.json(authResponseFactory.sessions(sessions, "Sessions fetched"));
  } catch (error) {
    next(error);
  }
};

export const revokeSessionById = async (
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  try {
    if (!req.user) {
      throw Errors.UNAUTHORIZED("Authentication is required");
    }

    const sessionId = req.params.id;
    if (!sessionId || Array.isArray(sessionId)) {
      throw Errors.BAD_REQUEST("Session id is required");
    }

    await revokeSession(req.user._id.toString(), sessionId);
    if (req.sessionId === sessionId) {
      clearRefreshTokenCookie(res);
    }

    res.json({ success: true, message: "Session revoked" });
  } catch (error) {
    next(error);
  }
};

export const getProfile = async (
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  try {
    if (!req.user) {
      throw Errors.UNAUTHORIZED("Authentication is required");
    }

    const profileResponse = authResponseFactory.profile(
      req.user,
      "Profile fetched successfully",
    );

    res.json(profileResponse);
  } catch (error) {
    next(error);
  }
};
