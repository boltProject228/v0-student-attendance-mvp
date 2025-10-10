"use client"
import { Navbar } from "@/components/navbar"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { UsersTab } from "@/components/admin/users-tab"
import { SubjectsTab } from "@/components/admin/subjects-tab"
import { GroupsTab } from "@/components/admin/groups-tab"
import { StudentsTab } from "@/components/admin/students-tab"

export default function AdminPage() {
  return (
    <>
      <Navbar />
      <div className="container mx-auto px-4 py-8">
        <div className="mb-6">
          <h1 className="text-3xl font-bold mb-2">Admin Panel</h1>
          <p className="text-muted-foreground">Manage users, subjects, groups, and students</p>
        </div>

        <Tabs defaultValue="users" className="w-full">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="users">Users</TabsTrigger>
            <TabsTrigger value="subjects">Subjects</TabsTrigger>
            <TabsTrigger value="groups">Groups</TabsTrigger>
            <TabsTrigger value="students">Students</TabsTrigger>
          </TabsList>

          <TabsContent value="users">
            <UsersTab />
          </TabsContent>

          <TabsContent value="subjects">
            <SubjectsTab />
          </TabsContent>

          <TabsContent value="groups">
            <GroupsTab />
          </TabsContent>

          <TabsContent value="students">
            <StudentsTab />
          </TabsContent>
        </Tabs>
      </div>
    </>
  )
}
