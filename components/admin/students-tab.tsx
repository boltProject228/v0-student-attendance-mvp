"use client"

import type React from "react"

import { useEffect, useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Trash2, Plus } from "lucide-react"

interface Student {
  _id: string
  fullName: string
  groupId: { _id: string; name: string }
}

interface Group {
  _id: string
  name: string
}

export function StudentsTab() {
  const [students, setStudents] = useState<Student[]>([])
  const [groups, setGroups] = useState<Group[]>([])
  const [loading, setLoading] = useState(true)
  const [formData, setFormData] = useState({ fullName: "", groupId: "" })

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    const [studentsRes, groupsRes] = await Promise.all([fetch("/api/admin/students"), fetch("/api/groups")])

    const studentsData = await studentsRes.json()
    const groupsData = await groupsRes.json()

    setStudents(studentsData.students || [])
    setGroups(groupsData.groups || [])
    setLoading(false)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const res = await fetch("/api/admin/students", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(formData),
    })

    if (res.ok) {
      setFormData({ fullName: "", groupId: "" })
      fetchData()
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm("Are you sure you want to delete this student?")) return

    await fetch(`/api/admin/students?id=${id}`, { method: "DELETE" })
    fetchData()
  }

  if (loading) return <p className="text-center py-8">Loading...</p>

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Add New Student</CardTitle>
          <CardDescription>Add a student to a group</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="fullName">Full Name</Label>
                <Input
                  id="fullName"
                  value={formData.fullName}
                  onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                  placeholder="e.g., Ivan Petrov"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="group">Group</Label>
                <Select value={formData.groupId} onValueChange={(v) => setFormData({ ...formData, groupId: v })}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select group" />
                  </SelectTrigger>
                  <SelectContent>
                    {groups.map((group) => (
                      <SelectItem key={group._id} value={group._id}>
                        {group.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <Button type="submit">
              <Plus className="h-4 w-4 mr-2" />
              Add Student
            </Button>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>All Students</CardTitle>
          <CardDescription>{students.length} students in the system</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-2 max-h-[500px] overflow-y-auto">
            {students.map((student) => (
              <div key={student._id} className="flex items-center justify-between p-3 border rounded-lg">
                <div>
                  <p className="font-medium">{student.fullName}</p>
                  <p className="text-sm text-muted-foreground">Group: {student.groupId?.name}</p>
                </div>
                <Button variant="destructive" size="sm" onClick={() => handleDelete(student._id)}>
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
