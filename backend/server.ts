// server.ts
import express, { Request, Response, NextFunction } from 'express';
import mongoose, { Schema, model, Document, Types } from 'mongoose';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import path from 'path';
import dotenv from 'dotenv';
import morgan from 'morgan';
import chalk from 'chalk';

// Load .env from project root
dotenv.config({ path: path.resolve(__dirname, '../.env') });

// Interfaces for models
interface IUser extends Document {
  _id: Types.ObjectId; // Добавляем поле _id с типом Types.ObjectId
  login: string;
  password: string;
  role: 'teacher' | 'head' | 'admin';
  fullName?: string;
  createdAt: Date;
}

interface IGroup extends Document {
  name: string;
  specialty: string;
  course: number;
  createdAt: Date;
}

interface IStudent extends Document {
  fullName: string;
  groupId: Types.ObjectId;
  createdAt: Date;
}

interface IAttendance extends Document {
  studentId: Types.ObjectId;
  groupId: Types.ObjectId;
  date: Date;
  status: 'present' | 'absent' | 'sick' | 'ithub';
  updatedBy: Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

// Extended Request interface for auth
interface AuthRequest extends Request {
  user?: { id: string; role: string };
}

const app = express();
app.use(cors());
app.use(express.json());

// Morgan with custom format and colors
morgan.token('body', (req: Request) => {
  if (Object.keys(req.body).length > 0) {
    return ` 📨 Body: ${JSON.stringify(req.body)}`;
  }
  return '';
});

app.use(
  morgan((tokens, req, res) => {
    const status = Number(tokens.status(req, res));
    let emoji = '✅';
    let color = chalk.green;

    if (status >= 400 && status < 500) {
      emoji = '⚠️';
      color = chalk.yellow;
    } else if (status >= 500) {
      emoji = '❌';
      color = chalk.red;
    }

    const timestamp = new Date().toISOString().replace('T', ' ').replace('Z', '').split('.')[0];
    const log = `[${timestamp}] ${tokens.method(req, res)} ${tokens.url(req, res)}${tokens.body(req, res)} ${emoji} ${status} - ${tokens['response-time'](req, res)}ms`;
    return color(log);
  })
);

console.log('📡 MONGO_URI из .env:', process.env.MONGO_URI);

// Connect to MongoDB
mongoose
  .connect(process.env.MONGO_URI as string)
  .then(() => console.log('✅ MongoDB подключена'))
  .catch((err) => console.error('❌ Ошибка MongoDB:', err));

// Mongoose schemas
const userSchema = new Schema<IUser>({
  login: { type: String, required: true, unique: true },
  password: { type: String, required: true }, // hashed
  role: { type: String, enum: ['teacher', 'head', 'admin'], default: 'teacher' },
  fullName: { type: String },
  createdAt: { type: Date, default: Date.now },
});
const User = model<IUser>('User', userSchema);

const groupSchema = new Schema<IGroup>({
  name: { type: String, required: true },
  specialty: { type: String, required: true },
  course: { type: Number, required: true },
  createdAt: { type: Date, default: Date.now },
});
const Group = model<IGroup>('Group', groupSchema);

const studentSchema = new Schema<IStudent>({
  fullName: { type: String, required: true },
  groupId: { type: Schema.Types.ObjectId, ref: 'Group', required: true },
  createdAt: { type: Date, default: Date.now },
});
const Student = model<IStudent>('Student', studentSchema);

const attendanceSchema = new Schema<IAttendance>({
  studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true },
  groupId: { type: Schema.Types.ObjectId, ref: 'Group', required: true },
  date: { type: Date, required: true },
  status: { type: String, enum: ['present', 'absent', 'sick', 'ithub'], required: true },
  updatedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});
const Attendance = model<IAttendance>('Attendance', attendanceSchema);

// Middleware for auth and roles
const authenticate = (req: AuthRequest, res: Response, next: NextFunction) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret') as { id: string; role: string };
    req.user = decoded;
    next();
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

const isHeadOrAdmin = (req: AuthRequest, res: Response, next: NextFunction) => {
  if (req.user?.role !== 'head' && req.user?.role !== 'admin') {
    return res.status(403).json({ error: 'Access denied' });
  }
  next();
};

// Auth routes


// Auth routes
app.post('/api/auth/login', async (req: Request, res: Response) => {
  const { login, password } = req.body as { login: string; password: string };
  try {
    const user = await User.findOne({ login }); // Убираем явное приведение as IUser | null
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (!bcrypt.compareSync(password, user.password)) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    const token = jwt.sign({ id: user._id.toString(), role: user.role }, process.env.JWT_SECRET || 'secret', { expiresIn: '1h' });
    res.status(200).json({
      token,
      user: { _id: user._id, login: user.login, role: user.role, fullName: user.fullName, createdAt: user.createdAt },
    });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// User CRUD (only for head/admin)
app.get('/api/admin/users', authenticate, isHeadOrAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const users = await User.find().select('-password');
    res.status(200).json(users);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

app.post('/api/admin/users', authenticate, isHeadOrAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const { login, password, role, fullName } = req.body as { login: string; password: string; role: string; fullName?: string };
    const hashed = bcrypt.hashSync(password, 10);
    const user = new User({ login, password: hashed, role, fullName });
    await user.save();
    res.status(201).json(user);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

app.delete('/api/admin/users/:id', authenticate, isHeadOrAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const deleted = await User.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'User not found' });
    res.status(200).json({ message: 'User deleted' });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// Group CRUD
app.get('/api/groups', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const groups = await Group.find();
    res.status(200).json(groups);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

app.post('/api/admin/groups', authenticate, isHeadOrAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const group = new Group(req.body);
    await group.save();
    res.status(201).json(group);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

app.delete('/api/admin/groups/:id', authenticate, isHeadOrAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const deleted = await Group.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Group not found' });
    res.status(200).json({ message: 'Group deleted' });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// Student CRUD
app.get('/api/students', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const students = await Student.find();
    res.status(200).json(students);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

app.post('/api/admin/students', authenticate, isHeadOrAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const student = new Student(req.body);
    await student.save();
    res.status(201).json(student);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

app.delete('/api/admin/students/:id', authenticate, isHeadOrAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const deleted = await Student.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Student not found' });
    res.status(200).json({ message: 'Student deleted' });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// Attendance CRUD (teachers can create/update, heads — all)
app.get('/api/attendance', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { groupId, date } = req.query as { groupId?: string; date?: string };
    const filter: any = {};
    if (groupId) filter.groupId = groupId;
    if (date) filter.date = new Date(date);
    const attendance = await Attendance.find(filter);
    res.status(200).json(attendance);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

app.post('/api/attendance', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const attendance = new Attendance({ ...req.body, updatedBy: req.user!.id });
    await attendance.save();
    res.status(201).json(attendance);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

app.put('/api/attendance/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const updated = await Attendance.findByIdAndUpdate(
      req.params.id,
      { ...req.body, updatedBy: req.user!.id, updatedAt: Date.now() },
      { new: true }
    );
    if (!updated) return res.status(404).json({ error: 'Attendance not found' });
    res.status(200).json(updated);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// Analytics (only for head)
app.get('/api/analytics', authenticate, isHeadOrAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const { startDate, endDate } = req.query as { startDate?: string; endDate?: string };
    const match: any = {};
    if (startDate) match.date = { $gte: new Date(startDate) };
    if (endDate) match.date = { ...match.date, $lte: new Date(endDate) };

    const analytics = await Attendance.aggregate<{ _id: string; count: number }>([
      { $match: match },
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]);

    const total = analytics.reduce((sum, item) => sum + item.count, 0) || 1;
    const stats = {
      averagePresent: ((analytics.find((a) => a._id === 'present')?.count || 0) / total * 100).toFixed(1),
      averageAbsent: ((analytics.find((a) => a._id === 'absent')?.count || 0) / total * 100).toFixed(1),
      averageSick: ((analytics.find((a) => a._id === 'sick')?.count || 0) / total * 100).toFixed(1),
      averageIThub: ((analytics.find((a) => a._id === 'ithub')?.count || 0) / total * 100).toFixed(1),
      totalStudents: await Student.countDocuments(),
      totalGroups: await Group.countDocuments(),
    };
    res.status(200).json(stats);
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// Test ping
app.get('/api/ping', (req: Request, res: Response) => {
  res.status(200).json({ message: '✅ Backend работает!' });
});

// Setup admin
app.post('/api/setup/admin', async (req: Request, res: Response) => {
  try {
    const { login, password, fullName } = req.body as { login: string; password: string; fullName?: string };
    const hashed = bcrypt.hashSync(password, 10);
    const user = new User({
      login,
      password: hashed,
      role: 'admin',
      fullName,
    });
    await user.save();
    res.status(201).json({ message: '✅ Admin created', user });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Сервер запущен на порту ${PORT}`));