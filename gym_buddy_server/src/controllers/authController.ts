import { NextFunction, Request, Response } from "express";
import User from "../models/User";
import { generateToken } from "../utils/generateToken";
import { authResponseFactory } from "./responseFactory/auth.responseFactory";
import { hashPassword, comparePassword } from "../utils/password";
import { Errors } from "../utils/AppError";

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

    const token = generateToken(user._id.toString());
    const registerResponse = authResponseFactory.create(
      user,
      token,
      "Register successful",
    );

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

    const token = generateToken(user._id.toString());
    const loginResponse = authResponseFactory.create(
      user,
      token,
      "Login successful",
    );

    res.json(loginResponse);
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
