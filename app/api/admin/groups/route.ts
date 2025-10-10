import { type NextRequest, NextResponse } from "next/server"
import connectDB from "@/lib/mongodb"
import Group from "@/models/Group"
import { verifyToken } from "@/lib/auth"

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

    const { name, specialty, course } = await request.json()

    if (!name || !specialty || !course) {
      return NextResponse.json({ error: "All fields are required" }, { status: 400 })
    }

    await connectDB()
    const group = await Group.create({ name, specialty, course })

    return NextResponse.json({ group })
  } catch (error) {
    console.error("[v0] Group creation error:", error)
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
    const groupId = searchParams.get("id")

    if (!groupId) {
      return NextResponse.json({ error: "Group ID is required" }, { status: 400 })
    }

    await connectDB()
    await Group.findByIdAndDelete(groupId)

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("[v0] Group deletion error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
