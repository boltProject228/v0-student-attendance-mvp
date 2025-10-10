import { type NextRequest, NextResponse } from "next/server"
import connectDB from "@/lib/mongodb"
import Subject from "@/models/Subject"
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

    await connectDB()

    const subjects = await Subject.find({ teacherId: payload.userId })

    return NextResponse.json({ subjects })
  } catch (error) {
    console.error("[v0] Subjects fetch error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
