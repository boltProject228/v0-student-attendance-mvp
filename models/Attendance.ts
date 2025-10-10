import mongoose, { Schema, type Document } from "mongoose"

export interface IAttendance extends Document {
  studentId: mongoose.Types.ObjectId
  groupId: mongoose.Types.ObjectId
  subjectId: mongoose.Types.ObjectId
  date: Date
  status: "present" | "absent" | "sick" | "wsk"
  updatedBy: mongoose.Types.ObjectId
  createdAt: Date
  updatedAt: Date
}

const AttendanceSchema = new Schema<IAttendance>(
  {
    studentId: {
      type: Schema.Types.ObjectId,
      ref: "Student",
      required: true,
    },
    groupId: {
      type: Schema.Types.ObjectId,
      ref: "Group",
      required: true,
    },
    subjectId: {
      type: Schema.Types.ObjectId,
      ref: "Subject",
      required: true,
    },
    date: {
      type: Date,
      required: true,
    },
    status: {
      type: String,
      enum: ["present", "absent", "sick", "wsk"],
      required: true,
    },
    updatedBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  {
    timestamps: true,
  },
)

// Index for faster queries
AttendanceSchema.index({ studentId: 1, subjectId: 1, date: 1 })
AttendanceSchema.index({ groupId: 1, date: 1 })

export default mongoose.models.Attendance || mongoose.model<IAttendance>("Attendance", AttendanceSchema)
