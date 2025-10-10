"use client"

import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { LogOut } from "lucide-react"
import { useState, useEffect } from "react"
import Link from "next/link"

export function Navbar() {
  const router = useRouter()
  const [user, setUser] = useState<{ login: string; role: string } | null>(null)

  useEffect(() => {
    fetch("/api/auth/me")
      .then((res) => res.json())
      .then((data) => {
        if (data.user) {
          setUser(data.user)
        }
      })
      .catch(() => {})
  }, [])

  const handleLogout = async () => {
    await fetch("/api/auth/logout", { method: "POST" })
    router.push("/login")
  }

  return (
    <nav className="border-b bg-background">
      <div className="container mx-auto px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-6">
          <h1 className="text-xl font-bold">Attendance System</h1>
          {user && (
            <div className="hidden md:flex items-center gap-4">
              {user.role === "teacher" && (
                <Link href="/subjects" className="text-sm hover:text-primary">
                  Subjects
                </Link>
              )}
              {user.role === "head" && (
                <>
                  <Link href="/analytics" className="text-sm hover:text-primary">
                    Analytics
                  </Link>
                  <Link href="/admin" className="text-sm hover:text-primary">
                    Admin
                  </Link>
                </>
              )}
            </div>
          )}
        </div>
        <div className="flex items-center gap-3">
          {user && (
            <>
              <span className="text-sm text-muted-foreground hidden sm:inline">{user.login}</span>
              <Button variant="outline" size="sm" onClick={handleLogout}>
                <LogOut className="h-4 w-4 mr-2" />
                Logout
              </Button>
            </>
          )}
        </div>
      </div>
    </nav>
  )
}
