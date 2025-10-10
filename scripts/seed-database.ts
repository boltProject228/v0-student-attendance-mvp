import { MongoClient } from "mongodb"
import bcrypt from "bcryptjs"

const MONGODB_URI = process.env.MONGODB_URI || "mongodb://localhost:27017/attendance"

async function seedDatabase() {
  const client = await MongoClient.connect(MONGODB_URI)
  const db = client.db()

  console.log("[v0] Connected to MongoDB")

  // Clear existing data
  await db.collection("users").deleteMany({})
  await db.collection("subjects").deleteMany({})
  await db.collection("groups").deleteMany({})
  await db.collection("students").deleteMany({})
  await db.collection("attendances").deleteMany({})

  console.log("[v0] Cleared existing data")

  // Create users
  const hashedPassword = await bcrypt.hash("password123", 10)

  const users = await db.collection("users").insertMany([
    {
      username: "teacher1",
      password: hashedPassword,
      fullName: "Иванов Иван Иванович",
      role: "teacher",
      createdAt: new Date(),
    },
    {
      username: "head1",
      password: hashedPassword,
      fullName: "Петров Петр Петрович",
      role: "head",
      createdAt: new Date(),
    },
    {
      username: "admin",
      password: hashedPassword,
      fullName: "Администратор",
      role: "head", // Head role has access to admin panel
      createdAt: new Date(),
    },
  ])

  console.log("[v0] Created users:", Object.values(users.insertedIds).length)

  const teacherId = users.insertedIds[0]

  // Create subjects
  const subjects = await db.collection("subjects").insertMany([
    {
      name: "Математика",
      teacherId: teacherId,
      createdAt: new Date(),
    },
    {
      name: "Физика",
      teacherId: teacherId,
      createdAt: new Date(),
    },
    {
      name: "Программирование",
      teacherId: teacherId,
      createdAt: new Date(),
    },
  ])

  console.log("[v0] Created subjects:", Object.values(subjects.insertedIds).length)

  const mathSubjectId = subjects.insertedIds[0]
  const physicsSubjectId = subjects.insertedIds[1]
  const programmingSubjectId = subjects.insertedIds[2]

  // Create groups
  const groups = await db.collection("groups").insertMany([
    {
      name: "ИС-21",
      course: 2,
      createdAt: new Date(),
    },
    {
      name: "ИС-22",
      course: 2,
      createdAt: new Date(),
    },
    {
      name: "ПО-31",
      course: 3,
      createdAt: new Date(),
    },
  ])

  console.log("[v0] Created groups:", Object.values(groups.insertedIds).length)

  const group1Id = groups.insertedIds[0]
  const group2Id = groups.insertedIds[1]
  const group3Id = groups.insertedIds[2]

  // Create students
  const students = await db.collection("students").insertMany([
    // Group ИС-21
    { fullName: "Алексеев Алексей", groupId: group1Id, createdAt: new Date() },
    { fullName: "Борисова Мария", groupId: group1Id, createdAt: new Date() },
    { fullName: "Васильев Дмитрий", groupId: group1Id, createdAt: new Date() },
    { fullName: "Григорьева Анна", groupId: group1Id, createdAt: new Date() },
    { fullName: "Дмитриев Сергей", groupId: group1Id, createdAt: new Date() },

    // Group ИС-22
    { fullName: "Егоров Михаил", groupId: group2Id, createdAt: new Date() },
    { fullName: "Жукова Елена", groupId: group2Id, createdAt: new Date() },
    { fullName: "Захаров Андрей", groupId: group2Id, createdAt: new Date() },
    { fullName: "Иванова Ольга", groupId: group2Id, createdAt: new Date() },
    { fullName: "Козлов Павел", groupId: group2Id, createdAt: new Date() },

    // Group ПО-31
    { fullName: "Лебедев Николай", groupId: group3Id, createdAt: new Date() },
    { fullName: "Морозова Татьяна", groupId: group3Id, createdAt: new Date() },
    { fullName: "Новиков Владимир", groupId: group3Id, createdAt: new Date() },
    { fullName: "Орлова Светлана", groupId: group3Id, createdAt: new Date() },
    { fullName: "Павлов Игорь", groupId: group3Id, createdAt: new Date() },
  ])

  console.log("[v0] Created students:", Object.values(students.insertedIds).length)

  // Create some sample attendance records
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  const attendanceRecords = []

  // Add attendance for math class for group ИС-21
  const group1Students = Object.values(students.insertedIds).slice(0, 5)
  for (let i = 0; i < group1Students.length; i++) {
    attendanceRecords.push({
      studentId: group1Students[i],
      subjectId: mathSubjectId,
      groupId: group1Id,
      date: today,
      status: i < 3 ? "present" : i === 3 ? "absent" : "late",
      markedBy: teacherId,
      createdAt: new Date(),
    })
  }

  // Add attendance for physics class for group ИС-22
  const group2Students = Object.values(students.insertedIds).slice(5, 10)
  for (let i = 0; i < group2Students.length; i++) {
    attendanceRecords.push({
      studentId: group2Students[i],
      subjectId: physicsSubjectId,
      groupId: group2Id,
      date: today,
      status: i < 4 ? "present" : "absent",
      markedBy: teacherId,
      createdAt: new Date(),
    })
  }

  await db.collection("attendances").insertMany(attendanceRecords)

  console.log("[v0] Created attendance records:", attendanceRecords.length)

  console.log("\n✅ Database seeded successfully!")
  console.log("\n📝 Test accounts:")
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  console.log("👨‍🏫 Teacher account:")
  console.log("   Username: teacher1")
  console.log("   Password: password123")
  console.log("   Role: teacher")
  console.log("")
  console.log("👔 Head account:")
  console.log("   Username: head1")
  console.log("   Password: password123")
  console.log("   Role: head")
  console.log("")
  console.log("🔧 Admin account:")
  console.log("   Username: admin")
  console.log("   Password: password123")
  console.log("   Role: head (with admin access)")
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

  await client.close()
}

seedDatabase().catch(console.error)
