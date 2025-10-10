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
    if (!payload || payload.role !== "head") {
      return NextResponse.json({ error: "Unauthorized" }, { status: 403 })
    }

    await connectDB()
    const students = await Student.find().populate("groupId", "name").sort({ fullName: 1 })

    return NextResponse.json({ students })
  } catch (error) {
    console.error("[v0] Students fetch error:", error)
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
    if (!payload || payload.role !== "head") {
      return NextResponse.json({ error: "Unauthorized" }, { status: 403 })
    }

    const { fullName, groupId } = await request.json()

    if (!fullName || !groupId) {
      return NextResponse.json({ error: "All fields are required" }, { status: 400 })
    }

    await connectDB()
    const student = await Student.create({ fullName, groupId })

    return NextResponse.json({ student })
  } catch (error) {
    console.error("[v0] Student creation error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

export async function DELETE(request: NextRequest) {
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
    const studentId = searchParams.get("id")

    if (!studentId) {
      return NextResponse.json({ error: "Student ID is required" }, { status: 400 })
    }

    await connectDB()
    await Student.findByIdAndDelete(studentId)

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("[v0] Student deletion error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
