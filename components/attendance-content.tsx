"use client"

import type React from "react"

import { useEffect, useState } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Check, X, Heart, AlertTriangle } from "lucide-react"

interface Student {
  _id: string
  fullName: string
}

interface AttendanceRecord {
  studentId: string
  status: "present" | "absent" | "sick" | "wsk"
}

export function AttendanceContent() {
  const [students, setStudents] = useState<Student[]>([])
  const [attendance, setAttendance] = useState<Map<string, string>>(new Map())
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const router = useRouter()
  const searchParams = useSearchParams()
  const groupId = searchParams.get("groupId")
  const subjectId = searchParams.get("subjectId")
  const [date, setDate] = useState(new Date().toISOString().split("T")[0])

  useEffect(() => {
    if (!groupId || !subjectId) {
      router.push("/subjects")
      return
    }

    fetchData()
  }, [groupId, subjectId, date])

  const fetchData = async () => {
    try {
      const [studentsRes, attendanceRes] = await Promise.all([
        fetch(`/api/students?groupId=${groupId}`),
        fetch(`/api/attendance?groupId=${groupId}&subjectId=${subjectId}&date=${date}`),
      ])

      const studentsData = await studentsRes.json()
      const attendanceData = await attendanceRes.json()

      setStudents(studentsData.students || [])

      const attendanceMap = new Map()
      attendanceData.attendance?.forEach((record: AttendanceRecord) => {
        attendanceMap.set(record.studentId, record.status)
      })
      setAttendance(attendanceMap)
      setLoading(false)
    } catch (error) {
      console.error("Fetch error:", error)
      setLoading(false)
    }
  }

  const updateAttendance = async (studentId: string, status: string) => {
    const newAttendance = new Map(attendance)
    newAttendance.set(studentId, status)
    setAttendance(newAttendance)

    setSaving(true)
    try {
      await fetch("/api/attendance", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          studentId,
          groupId,
          subjectId,
          date,
          status,
        }),
      })
    } catch (error) {
      console.error("Save error:", error)
    } finally {
      setSaving(false)
    }
  }

  const getStatusButton = (
    studentId: string,
    status: string,
    icon: React.ReactNode,
    label: string,
    variant: string,
  ) => {
    const isActive = attendance.get(studentId) === status
    return (
      <Button
        size="sm"
        variant={isActive ? "default" : "outline"}
        onClick={() => updateAttendance(studentId, status)}
        disabled={saving}
        className="flex-1"
      >
        {icon}
        <span className="ml-1 hidden sm:inline">{label}</span>
      </Button>
    )
  }

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <p className="text-center text-muted-foreground">Loading...</p>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
      <div className="mb-6">
        <Button variant="ghost" onClick={() => router.back()} className="mb-4">
          ← Back to Groups
        </Button>
        <h1 className="text-3xl font-bold mb-4">Mark Attendance</h1>
        <div className="flex items-center gap-3">
          <label className="text-sm font-medium">Date:</label>
          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="px-3 py-2 border rounded-md"
          />
        </div>
      </div>

      {students.length === 0 ? (
        <Card>
          <CardContent className="py-8 text-center text-muted-foreground">No students in this group</CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {students.map((student) => (
            <Card key={student._id}>
              <CardHeader className="pb-3">
                <CardTitle className="text-base font-medium">{student.fullName}</CardTitle>
              </CardHeader>
              <CardContent className="pt-0">
                <div className="flex gap-2">
                  {getStatusButton(student._id, "present", <Check className="h-4 w-4" />, "Present", "default")}
                  {getStatusButton(student._id, "absent", <X className="h-4 w-4" />, "Absent", "destructive")}
                  {getStatusButton(student._id, "sick", <Heart className="h-4 w-4" />, "Sick", "secondary")}
                  {getStatusButton(student._id, "wsk", <AlertTriangle className="h-4 w-4" />, "WSK", "outline")}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
