import { type NextRequest, NextResponse } from "next/server"
import connectDB from "@/lib/mongodb"
import Attendance from "@/models/Attendance"
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
    const groupId = searchParams.get("groupId")
    const subjectId = searchParams.get("subjectId")
    const specialty = searchParams.get("specialty")
    const course = searchParams.get("course")
    const startDate = searchParams.get("startDate")
    const endDate = searchParams.get("endDate")

    await connectDB()

    const filter: any = {}

    if (groupId) filter.groupId = groupId
    if (subjectId) filter.subjectId = subjectId
    if (startDate || endDate) {
      filter.date = {}
      if (startDate) filter.date.$gte = new Date(startDate)
      if (endDate) filter.date.$lte = new Date(endDate)
    }

    let attendance = await Attendance.find(filter)
      .populate("studentId", "fullName groupId")
      .populate("groupId", "name specialty course")
      .populate("subjectId", "name")
      .sort({ date: -1 })
      .limit(1000)

    // Filter by specialty or course if needed
    if (specialty || course) {
      attendance = attendance.filter((record: any) => {
        if (specialty && record.groupId?.specialty !== specialty) return false
        if (course && record.groupId?.course !== Number.parseInt(course)) return false
        return true
      })
    }

    // Calculate statistics
    const stats = {
      present: attendance.filter((r) => r.status === "present").length,
      absent: attendance.filter((r) => r.status === "absent").length,
      sick: attendance.filter((r) => r.status === "sick").length,
      wsk: attendance.filter((r) => r.status === "wsk").length,
      total: attendance.length,
    }

    return NextResponse.json({ attendance, stats })
  } catch (error) {
    console.error("[v0] Analytics fetch error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
