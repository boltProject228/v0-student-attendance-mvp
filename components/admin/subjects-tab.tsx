"use client"

import type React from "react"

import { useEffect, useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Trash2, Plus } from "lucide-react"

interface Subject {
  _id: string
  name: string
  teacherId: { _id: string; login: string }
}

interface User {
  _id: string
  login: string
  role: string
}

export function SubjectsTab() {
  const [subjects, setSubjects] = useState<Subject[]>([])
  const [teachers, setTeachers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [formData, setFormData] = useState({ name: "", teacherId: "" })

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    const [subjectsRes, usersRes] = await Promise.all([fetch("/api/admin/subjects"), fetch("/api/admin/users")])

    const subjectsData = await subjectsRes.json()
    const usersData = await usersRes.json()

    setSubjects(subjectsData.subjects || [])
    setTeachers(usersData.users?.filter((u: User) => u.role === "teacher") || [])
    setLoading(false)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const res = await fetch("/api/admin/subjects", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(formData),
    })

    if (res.ok) {
      setFormData({ name: "", teacherId: "" })
      fetchData()
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm("Are you sure you want to delete this subject?")) return

    await fetch(`/api/admin/subjects?id=${id}`, { method: "DELETE" })
    fetchData()
  }

  if (loading) return <p className="text-center py-8">Loading...</p>

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Add New Subject</CardTitle>
          <CardDescription>Create a new subject and assign a teacher</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="name">Subject Name</Label>
                <Input
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="e.g., Physics, Mathematics"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="teacher">Teacher</Label>
                <Select value={formData.teacherId} onValueChange={(v) => setFormData({ ...formData, teacherId: v })}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select teacher" />
                  </SelectTrigger>
                  <SelectContent>
                    {teachers.map((teacher) => (
                      <SelectItem key={teacher._id} value={teacher._id}>
                        {teacher.login}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <Button type="submit">
              <Plus className="h-4 w-4 mr-2" />
              Add Subject
            </Button>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>All Subjects</CardTitle>
          <CardDescription>{subjects.length} subjects in the system</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {subjects.map((subject) => (
              <div key={subject._id} className="flex items-center justify-between p-3 border rounded-lg">
                <div>
                  <p className="font-medium">{subject.name}</p>
                  <p className="text-sm text-muted-foreground">Teacher: {subject.teacherId?.login}</p>
                </div>
                <Button variant="destructive" size="sm" onClick={() => handleDelete(subject._id)}>
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
