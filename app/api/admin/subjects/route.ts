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
    const subjects = await Subject.find().populate("teacherId", "login").sort({ name: 1 })

    return NextResponse.json({ subjects })
  } catch (error) {
    console.error("[v0] Subjects fetch error:", error)
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

    const { name, teacherId } = await request.json()

    if (!name || !teacherId) {
      return NextResponse.json({ error: "All fields are required" }, { status: 400 })
    }

    await connectDB()
    const subject = await Subject.create({ name, teacherId })

    return NextResponse.json({ subject })
  } catch (error) {
    console.error("[v0] Subject creation error:", error)
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
    const subjectId = searchParams.get("id")

    if (!subjectId) {
      return NextResponse.json({ error: "Subject ID is required" }, { status: 400 })
    }

    await connectDB()
    await Subject.findByIdAndDelete(subjectId)

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("[v0] Subject deletion error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
