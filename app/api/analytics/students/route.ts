import { type NextRequest, NextResponse } from "next/server"
import connectDB from "@/lib/mongodb"
import Attendance from "@/models/Attendance"
import Student from "@/models/Student"
import { verifyToken } from "@/lib/auth"

export async function GET(request: NextRequest) {
  try {
    const token = request.cookies.get("token")?.value
    if (!token) {
      return NextResponse.json({ error: "Not authenticated" }, { status: 401 })
    }

    const payload = verifyToken(token)
    if (!payload || payload.role !== "head") {
      return NextResponse.json({ error: "Unauthorized" }, { status: 403 })
    }

    const { searchParams } = new URL(request.url)
    const studentId = searchParams.get("studentId")

    if (!studentId) {
      return NextResponse.json({ error: "Student ID is required" }, { status: 400 })
    }

    await connectDB()

    const student = await Student.findById(studentId).populate("groupId")
    if (!student) {
      return NextResponse.json({ error: "Student not found" }, { status: 404 })
    }

    const attendance = await Attendance.find({ studentId })
      .populate("subjectId", "name")
      .populate("groupId", "name")
      .sort({ date: -1 })

    const stats = {
      present: attendance.filter((r) => r.status === "present").length,
      absent: attendance.filter((r) => r.status === "absent").length,
      sick: attendance.filter((r) => r.status === "sick").length,
      wsk: attendance.filter((r) => r.status === "wsk").length,
      total: attendance.length,
    }

    return NextResponse.json({ student, attendance, stats })
  } catch (error) {
    console.error("[v0] Student analytics fetch error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
