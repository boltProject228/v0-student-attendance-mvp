"use client"

import type React from "react"

import { useEffect, useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Trash2, Plus } from "lucide-react"

interface Group {
  _id: string
  name: string
  specialty: string
  course: number
}

const SPECIALTIES = ["ПО", "БКЕ", "СИБ", "ТЭ", "М"]

export function GroupsTab() {
  const [groups, setGroups] = useState<Group[]>([])
  const [loading, setLoading] = useState(true)
  const [formData, setFormData] = useState({ name: "", specialty: "ПО", course: "1" })

  useEffect(() => {
    fetchGroups()
  }, [])

  const fetchGroups = async () => {
    const res = await fetch("/api/groups")
    const data = await res.json()
    setGroups(data.groups || [])
    setLoading(false)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const res = await fetch("/api/admin/groups", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ...formData, course: Number.parseInt(formData.course) }),
    })

    if (res.ok) {
      setFormData({ name: "", specialty: "ПО", course: "1" })
      fetchGroups()
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm("Are you sure you want to delete this group?")) return

    await fetch(`/api/admin/groups?id=${id}`, { method: "DELETE" })
    fetchGroups()
  }

  if (loading) return <p className="text-center py-8">Loading...</p>

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Add New Group</CardTitle>
          <CardDescription>Create a new student group</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-3">
              <div className="space-y-2">
                <Label htmlFor="groupName">Group Name</Label>
                <Input
                  id="groupName"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="e.g., ПО 234"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="specialty">Specialty</Label>
                <Select value={formData.specialty} onValueChange={(v) => setFormData({ ...formData, specialty: v })}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {SPECIALTIES.map((s) => (
                      <SelectItem key={s} value={s}>
                        {s}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="course">Course</Label>
                <Select value={formData.course} onValueChange={(v) => setFormData({ ...formData, course: v })}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="1">1</SelectItem>
                    <SelectItem value="2">2</SelectItem>
                    <SelectItem value="3">3</SelectItem>
                    <SelectItem value="4">4</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <Button type="submit">
              <Plus className="h-4 w-4 mr-2" />
              Add Group
            </Button>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>All Groups</CardTitle>
          <CardDescription>{groups.length} groups in the system</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {groups.map((group) => (
              <div key={group._id} className="flex items-center justify-between p-3 border rounded-lg">
                <div>
                  <p className="font-medium">{group.name}</p>
                  <p className="text-sm text-muted-foreground">
                    {group.specialty} • Course {group.course}
                  </p>
                </div>
                <Button variant="destructive" size="sm" onClick={() => handleDelete(group._id)}>
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
