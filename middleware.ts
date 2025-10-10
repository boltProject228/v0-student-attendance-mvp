import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"
import { verifyToken } from "./lib/auth"

export function middleware(request: NextRequest) {
  const token = request.cookies.get("token")?.value

  // Public routes
  if (request.nextUrl.pathname === "/login") {
    if (token && verifyToken(token)) {
      return NextResponse.redirect(new URL("/subjects", request.url))
    }
    return NextResponse.next()
  }

  // Protected routes
  if (!token) {
    return NextResponse.redirect(new URL("/login", request.url))
  }

  const payload = verifyToken(token)
  if (!payload) {
    const response = NextResponse.redirect(new URL("/login", request.url))
    response.cookies.delete("token")
    return response
  }

  // Role-based access control
  if (request.nextUrl.pathname.startsWith("/analytics") && payload.role !== "head") {
    return NextResponse.redirect(new URL("/subjects", request.url))
  }

  if (request.nextUrl.pathname.startsWith("/admin") && payload.role !== "head") {
    return NextResponse.redirect(new URL("/subjects", request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
}
