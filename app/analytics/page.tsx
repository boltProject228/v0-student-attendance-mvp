"use client"

import { useEffect, useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Navbar } from "@/components/navbar"
import { Button } from "@/components/ui/button"

interface Stats {
  present: number
  absent: number
  sick: number
  wsk: number
  total: number
}

interface AttendanceRecord {
  _id: string
  studentId: { _id: string; fullName: string }
  groupId: { name: string; specialty: string; course: number }
  subjectId: { name: string }
  date: string
  status: string
}

const SPECIALTIES = ["ПО", "БКЕ", "СИБ", "ТЭ", "М"]

export default function AnalyticsPage() {
  const [stats, setStats] = useState<Stats>({ present: 0, absent: 0, sick: 0, wsk: 0, total: 0 })
  const [attendance, setAttendance] = useState<AttendanceRecord[]>([])
  const [groups, setGroups] = useState<any[]>([])
  const [subjects, setSubjects] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  const [filters, setFilters] = useState({
    groupId: "all",
    subjectId: "all",
    specialty: "all",
    course: "all",
    startDate: "",
    endDate: "",
  })

  useEffect(() => {
    fetchGroups()
    fetchSubjects()
  }, [])

  useEffect(() => {
    fetchAnalytics()
  }, [filters])

  const fetchGroups = async () => {
    const res = await fetch("/api/groups")
    const data = await res.json()
    setGroups(data.groups || [])
  }

  const fetchSubjects = async () => {
    const res = await fetch("/api/admin/subjects")
    const data = await res.json()
    setSubjects(data.subjects || [])
  }

  const fetchAnalytics = async () => {
    const params = new URLSearchParams()
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== "all") params.append(key, value)
    })

    const res = await fetch(`/api/analytics?${params}`)
    const data = await res.json()
    setStats(data.stats || { present: 0, absent: 0, sick: 0, wsk: 0, total: 0 })
    setAttendance(data.attendance || [])
    setLoading(false)
  }

  const updateFilter = (key: string, value: string) => {
    setFilters((prev) => ({ ...prev, [key]: value }))
  }

  const clearFilters = () => {
    setFilters({
      groupId: "all",
      subjectId: "all",
      specialty: "all",
      course: "all",
      startDate: "",
      endDate: "",
    })
  }

  const getPercentage = (value: number) => {
    return stats.total > 0 ? ((value / stats.total) * 100).toFixed(1) : "0"
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
          <h1 className="text-3xl font-bold mb-2">Analytics Dashboard</h1>
          <p className="text-muted-foreground">View and analyze attendance data</p>
        </div>

        <div className="mb-6 space-y-3">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            <Select value={filters.groupId} onValueChange={(v) => updateFilter("groupId", v)}>
              <SelectTrigger>
                <SelectValue placeholder="All Groups" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Groups</SelectItem>
                {groups.map((g) => (
                  <SelectItem key={g._id} value={g._id}>
                    {g.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={filters.subjectId} onValueChange={(v) => updateFilter("subjectId", v)}>
              <SelectTrigger>
                <SelectValue placeholder="All Subjects" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Subjects</SelectItem>
                {subjects.map((s) => (
                  <SelectItem key={s._id} value={s._id}>
                    {s.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={filters.specialty} onValueChange={(v) => updateFilter("specialty", v)}>
              <SelectTrigger>
                <SelectValue placeholder="All Specialties" />
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

            <Select value={filters.course} onValueChange={(v) => updateFilter("course", v)}>
              <SelectTrigger>
                <SelectValue placeholder="All Courses" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Courses</SelectItem>
                <SelectItem value="1">Course 1</SelectItem>
                <SelectItem value="2">Course 2</SelectItem>
                <SelectItem value="3">Course 3</SelectItem>
                <SelectItem value="4">Course 4</SelectItem>
              </SelectContent>
            </Select>

            <Input
              type="date"
              placeholder="Start Date"
              value={filters.startDate}
              onChange={(e) => updateFilter("startDate", e.target.value)}
            />

            <Input
              type="date"
              placeholder="End Date"
              value={filters.endDate}
              onChange={(e) => updateFilter("endDate", e.target.value)}
            />
          </div>

          <Button variant="outline" onClick={clearFilters} className="w-full sm:w-auto bg-transparent">
            Clear Filters
          </Button>
        </div>

        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4 mb-6">
          <Card>
            <CardHeader className="pb-3">
              <CardDescription>Present</CardDescription>
              <CardTitle className="text-3xl text-green-600">{stats.present}</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">{getPercentage(stats.present)}% of total</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-3">
              <CardDescription>Absent</CardDescription>
              <CardTitle className="text-3xl text-red-600">{stats.absent}</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">{getPercentage(stats.absent)}% of total</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-3">
              <CardDescription>Sick Leave</CardDescription>
              <CardTitle className="text-3xl text-blue-600">{stats.sick}</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">{getPercentage(stats.sick)}% of total</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-3">
              <CardDescription>WSK</CardDescription>
              <CardTitle className="text-3xl text-orange-600">{stats.wsk}</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">{getPercentage(stats.wsk)}% of total</p>
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Recent Attendance Records</CardTitle>
            <CardDescription>Showing {attendance.length} records</CardDescription>
          </CardHeader>
          <CardContent>
            {attendance.length === 0 ? (
              <p className="text-center text-muted-foreground py-8">No records found</p>
            ) : (
              <div className="space-y-2 max-h-[600px] overflow-y-auto">
                {attendance.map((record) => (
                  <div key={record._id} className="flex items-center justify-between p-3 border rounded-lg">
                    <div className="flex-1">
                      <p className="font-medium">{record.studentId?.fullName}</p>
                      <p className="text-sm text-muted-foreground">
                        {record.groupId?.name} • {record.subjectId?.name}
                      </p>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className="text-sm text-muted-foreground">
                        {new Date(record.date).toLocaleDateString()}
                      </span>
                      <span
                        className={`px-3 py-1 rounded-full text-xs font-medium ${
                          record.status === "present"
                            ? "bg-green-100 text-green-700"
                            : record.status === "absent"
                              ? "bg-red-100 text-red-700"
                              : record.status === "sick"
                                ? "bg-blue-100 text-blue-700"
                                : "bg-orange-100 text-orange-700"
                        }`}
                      >
                        {record.status}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </>
  )
}
