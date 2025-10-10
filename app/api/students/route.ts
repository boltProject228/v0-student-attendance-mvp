import { type NextRequest, NextResponse } from "next/server"
import connectDB from "@/lib/mongodb"
import Student from "@/models/Student"
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

    if (!groupId) {
      return NextResponse.json({ error: "Group ID is required" }, { status: 400 })
    }

    await connectDB()

    const students = await Student.find({ groupId }).sort({ fullName: 1 })

    return NextResponse.json({ students })
  } catch (error) {
    console.error("[v0] Students fetch error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
