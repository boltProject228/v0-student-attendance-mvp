import { type NextRequest, NextResponse } from "next/server"
import connectDB from "@/lib/mongodb"
import User from "@/models/User"
import { verifyToken, hashPassword } from "@/lib/auth"

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
    const users = await User.find().select("-password").sort({ createdAt: -1 })

    return NextResponse.json({ users })
  } catch (error) {
    console.error("[v0] Users fetch error:", error)
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

    const { login, password, role } = await request.json()

    if (!login || !password || !role) {
      return NextResponse.json({ error: "All fields are required" }, { status: 400 })
    }

    await connectDB()

    const existingUser = await User.findOne({ login })
    if (existingUser) {
      return NextResponse.json({ error: "User already exists" }, { status: 400 })
    }

    const hashedPassword = await hashPassword(password)
    const user = await User.create({
      login,
      password: hashedPassword,
      role,
    })

    return NextResponse.json({ user: { id: user._id, login: user.login, role: user.role } })
  } catch (error) {
    console.error("[v0] User creation error:", error)
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
    const userId = searchParams.get("id")

    if (!userId) {
      return NextResponse.json({ error: "User ID is required" }, { status: 400 })
    }

    await connectDB()
    await User.findByIdAndDelete(userId)

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("[v0] User deletion error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
