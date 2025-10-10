import mongoose, { Schema, type Document } from "mongoose"

export interface IGroup extends Document {
  name: string
  specialty: string
  course: number
  createdAt: Date
}

const GroupSchema = new Schema<IGroup>({
  name: {
    type: String,
    required: true,
    unique: true,
  },
  specialty: {
    type: String,
    required: true,
  },
  course: {
    type: Number,
    required: true,
    min: 1,
    max: 4,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
})

export default mongoose.models.Group || mongoose.model<IGroup>("Group", GroupSchema)
