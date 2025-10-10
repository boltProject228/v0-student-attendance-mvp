import mongoose, { Schema, type Document } from "mongoose"

export interface IStudent extends Document {
  fullName: string
  groupId: mongoose.Types.ObjectId
  createdAt: Date
}

const StudentSchema = new Schema<IStudent>({
  fullName: {
    type: String,
    required: true,
  },
  groupId: {
    type: Schema.Types.ObjectId,
    ref: "Group",
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
})

export default mongoose.models.Student || mongoose.model<IStudent>("Student", StudentSchema)
