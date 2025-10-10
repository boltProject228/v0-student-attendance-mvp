import { type NextRequest, NextResponse } from "next/server"
import connectDB from "@/lib/mongodb"
import Group from "@/models/Group"
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
    const specialty = searchParams.get("specialty")
    const course = searchParams.get("course")
    const search = searchParams.get("search")

    await connectDB()

    const filter: any = {}
    if (specialty) filter.specialty = specialty
    if (course) filter.course = Number.parseInt(course)
    if (search) filter.name = { $regex: search, $options: "i" }

    const groups = await Group.find(filter).sort({ name: 1 })

    return NextResponse.json({ groups })
  } catch (error) {
    console.error("[v0] Groups fetch error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
