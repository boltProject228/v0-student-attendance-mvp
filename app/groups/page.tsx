"use client"

import { useEffect, useState } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Navbar } from "@/components/navbar"
import { Users, Search } from "lucide-react"
import { Button } from "@/components/ui/button"

interface Group {
  _id: string
  name: string
  specialty: string
  course: number
}

const SPECIALTIES = ["ПО", "БКЕ", "СИБ", "ТЭ", "М"]

export default function GroupsPage() {
  const [groups, setGroups] = useState<Group[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState("")
  const [specialty, setSpecialty] = useState<string>("")
  const [course, setCourse] = useState<string>("")
  const router = useRouter()
  const searchParams = useSearchParams()
  const subjectId = searchParams.get("subjectId")

  useEffect(() => {
    if (!subjectId) {
      router.push("/subjects")
      return
    }

    fetchGroups()
  }, [subjectId, specialty, course, search])

  const fetchGroups = () => {
    const params = new URLSearchParams()
    if (specialty) params.append("specialty", specialty)
    if (course) params.append("course", course)
    if (search) params.append("search", search)

    fetch(`/api/groups?${params}`)
      .then((res) => res.json())
      .then((data) => {
        setGroups(data.groups || [])
        setLoading(false)
      })
      .catch(() => setLoading(false))
  }

  if (loading) {
    return (
      <>
        <Navbar />
        <div className="container mx-auto px-4 py-8">
          <p className="text-center text-muted-foreground">Loading...</p>
        </div>
      </>
    )
  }

  return (
    <>
      <Navbar />
      <div className="container mx-auto px-4 py-8">
        <div className="mb-6">
          <Button variant="ghost" onClick={() => router.push("/subjects")} className="mb-4">
            ← Back to Subjects
          </Button>
          <h1 className="text-3xl font-bold mb-2">Groups</h1>
          <p className="text-muted-foreground">Select a group to mark attendance</p>
        </div>

        <div className="mb-6 flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search groups..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-9"
            />
          </div>
          <Select value={specialty} onValueChange={setSpecialty}>
            <SelectTrigger className="w-full sm:w-[180px]">
              <SelectValue placeholder="Specialty" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Specialties</SelectItem>
              {SPECIALTIES.map((s) => (
                <SelectItem key={s} value={s}>
                  {s}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Select value={course} onValueChange={setCourse}>
            <SelectTrigger className="w-full sm:w-[180px]">
              <SelectValue placeholder="Course" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Courses</SelectItem>
              <SelectItem value="1">Course 1</SelectItem>
              <SelectItem value="2">Course 2</SelectItem>
              <SelectItem value="3">Course 3</SelectItem>
              <SelectItem value="4">Course 4</SelectItem>
            </SelectContent>
          </Select>
        </div>

        {groups.length === 0 ? (
          <Card>
            <CardContent className="py-8 text-center text-muted-foreground">No groups found</CardContent>
          </Card>
        ) : (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {groups.map((group) => (
              <Card
                key={group._id}
                className="cursor-pointer hover:shadow-md transition-shadow"
                onClick={() => router.push(`/attendance?groupId=${group._id}&subjectId=${subjectId}`)}
              >
                <CardHeader>
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-primary/10 rounded-lg">
                      <Users className="h-6 w-6 text-primary" />
                    </div>
                    <div>
                      <CardTitle className="text-lg">{group.name}</CardTitle>
                      <CardDescription>
                        {group.specialty} • Course {group.course}
                      </CardDescription>
                    </div>
                  </div>
                </CardHeader>
              </Card>
            ))}
          </div>
        )}
      </div>
    </>
  )
}
