import { Suspense } from "react"
import { GroupsContent } from "@/components/groups-content"
import { Navbar } from "@/components/navbar"

export default function GroupsPage() {
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
        <GroupsContent />
      </Suspense>
    </>
  )
}
