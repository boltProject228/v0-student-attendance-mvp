import { Suspense } from "react"
import { AttendanceContent } from "@/components/attendance-content"
import { Navbar } from "@/components/navbar"

export default function AttendancePage() {
  return (
    <>
      <Navbar />
      <Suspense
        fallback={
          <div className="container mx-auto px-4 py-8">
            <p className="text-center text-muted-foreground">Loading...</p>
          </div>
        }
      >
        <AttendanceContent />
      </Suspense>
    </>
  )
}
