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
    if (!payload) {
      return NextResponse.json({ error: "Invalid token" }, { status: 401 })
    }

    const { searchParams } = new URL(request.url)
    const groupId = searchParams.get("groupId")
    const subjectId = searchParams.get("subjectId")
    const date = searchParams.get("date")

    if (!groupId || !subjectId || !date) {
      return NextResponse.json({ error: "Group ID, Subject ID, and date are required" }, { status: 400 })
    }

    await connectDB()

    const attendance = await Attendance.find({
      groupId,
      subjectId,
      date: new Date(date),
    })

    return NextResponse.json({ attendance })
  } catch (error) {
    console.error("[v0] Attendance fetch error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const token = request.cookies.get("token")?.value
    if (!token) {
      return NextResponse.json({ error: "Not authenticated" }, { status: 401 })
    }

    const payload = verifyToken(token)
    if (!payload) {
      return NextResponse.json({ error: "Invalid token" }, { status: 401 })
    }

    const { studentId, groupId, subjectId, date, status } = await request.json()

    if (!studentId || !groupId || !subjectId || !date || !status) {
      return NextResponse.json({ error: "All fields are required" }, { status: 400 })
    }

    await connectDB()

    const attendance = await Attendance.findOneAndUpdate(
      {
        studentId,
        groupId,
        subjectId,
        date: new Date(date),
      },
      {
        status,
        updatedBy: payload.userId,
      },
      {
        upsert: true,
        new: true,
      },
    )

    return NextResponse.json({ attendance })
  } catch (error) {
    console.error("[v0] Attendance update error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
