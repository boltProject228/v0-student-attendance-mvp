import mongoose, { Schema, type Document } from "mongoose"

export interface IUser extends Document {
  login: string
  password: string
  role: "teacher" | "head"
  createdAt: Date
}

const UserSchema = new Schema<IUser>({
  login: {
    type: String,
    required: true,
    unique: true,
  },
  password: {
    type: String,
    required: true,
  },
  role: {
    type: String,
    enum: ["teacher", "head"],
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
})

export default mongoose.models.User || mongoose.model<IUser>("User", UserSchema)
