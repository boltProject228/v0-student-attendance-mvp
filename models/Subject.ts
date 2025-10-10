import mongoose, { Schema, type Document } from "mongoose"

export interface ISubject extends Document {
  name: string
  teacherId: mongoose.Types.ObjectId
  createdAt: Date
}

const SubjectSchema = new Schema<ISubject>({
  name: {
    type: String,
    required: true,
  },
  teacherId: {
    type: Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
})

export default mongoose.models.Subject || mongoose.model<ISubject>("Subject", SubjectSchema)
