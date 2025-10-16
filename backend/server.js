const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const path = require('path');
const dotenv = require('dotenv');
const morgan = require('morgan');
const chalk = require('chalk');

// Load .env from project root
dotenv.config({ path: path.resolve(__dirname, '.env') });

const app = express();
app.use(cors());
app.use(express.json());

// Morgan with custom format and colors
morgan.token('body', (req) => {
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

console.log('📡 MONGO_URL:', process.env.MONGO_URL || 'No MONGO_URL provided');


// Connect to MongoDB with options for MongoDB Atlas
mongoose
  .connect(process.env.MONGO_URL, {
    serverSelectionTimeoutMS: 5000, // Timeout for server selection
    socketTimeoutMS: 45000, // Timeout for socket inactivity
  })
  .then(() => console.log('✅ MongoDB connected successfully'))
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err.message);
    process.exit(1); // Exit process on connection failure
  });

// Mongoose schemas
const userSchema = new mongoose.Schema({
  login: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['teacher', 'head', 'admin'], default: 'teacher' },
  fullName: { type: String },
  createdAt: { type: Date, default: Date.now },
});
const User = mongoose.model('User', userSchema);

const groupSchema = new mongoose.Schema({
  name: { type: String, required: true },
  specialty: { type: String, required: true },
  course: { type: Number, required: true },
  createdAt: { type: Date, default: Date.now },
});
const Group = mongoose.model('Group', groupSchema);

const studentSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  groupId: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true },
  createdAt: { type: Date, default: Date.now },
});
const Student = mongoose.model('Student', studentSchema);

const attendanceSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  groupId: { type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true },
  date: { type: Date, required: true },
  status: { type: String, enum: ['present', 'absent', 'sick', 'ithub'], required: true },
  updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});
const Attendance = mongoose.model('Attendance', attendanceSchema);

// Middleware for auth and roles
const authenticate = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');
    req.user = decoded;
    next();
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

const isHeadOrAdmin = (req, res, next) => {
  if (req.user?.role !== 'head' && req.user?.role !== 'admin') {
    return res.status(403).json({ error: 'Access denied' });
  }
  next();
};

// Auth routes
app.post('/api/auth/login', async (req, res) => {
  const { login, password } = req.body;
  try {
    const user = await User.findOne({ login });
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (!bcrypt.compareSync(password, user.password)) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    const token = jwt.sign({ id: user._id.toString(), role: user.role }, process.env.JWT_SECRET || 'secret', {
      expiresIn: '1h',
    });
    res.status(200).json({
      token,
      user: { _id: user._id, login: user.login, role: user.role, fullName: user.fullName, createdAt: user.createdAt },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// User CRUD (only for head/admin)
app.get('/api/admin/users', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const users = await User.find().select('-password');
    res.status(200).json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/admin/users', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const { login, password, role, fullName } = req.body;
    const hashed = bcrypt.hashSync(password, 10);
    const user = new User({ login, password: hashed, role, fullName });
    await user.save();
    res.status(201).json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/admin/users/:id', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const deleted = await User.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'User not found' });
    res.status(200).json({ message: 'User deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Group CRUD
app.get('/api/groups', authenticate, async (req, res) => {
  try {
    const groups = await Group.find();
    res.status(200).json(groups);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/admin/groups', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const group = new Group(req.body);
    await group.save();
    res.status(201).json(group);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/admin/groups/:id', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const deleted = await Group.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Group not found' });
    res.status(200).json({ message: 'Group deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Student CRUD
app.get('/api/students', authenticate, async (req, res) => {
  try {
    const students = await Student.find();
    res.status(200).json(students);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/admin/students', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const student = new Student(req.body);
    await student.save();
    res.status(201).json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/admin/students/:id', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const deleted = await Student.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Student not found' });
    res.status(200).json({ message: 'Student deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Attendance CRUD
app.get('/api/attendance', authenticate, async (req, res) => {
  try {
    const { groupId, date } = req.query;
    const filter = {};
    if (groupId) filter.groupId = groupId;
    if (date) filter.date = new Date(date);
    const attendance = await Attendance.find(filter);
    res.status(200).json(attendance);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/attendance', authenticate, async (req, res) => {
  try {
    const attendance = new Attendance({ ...req.body, updatedBy: req.user.id });
    await attendance.save();
    res.status(201).json(attendance);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/attendance/:id', authenticate, async (req, res) => {
  try {
    const updated = await Attendance.findByIdAndUpdate(
      req.params.id,
      { ...req.body, updatedBy: req.user.id, updatedAt: Date.now() },
      { new: true }
    );
    if (!updated) return res.status(404).json({ error: 'Attendance not found' });
    res.status(200).json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Analytics (only for head/admin)
app.get('/api/analytics', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const match = {};
    if (startDate) match.date = { $gte: new Date(startDate) };
    if (endDate) match.date = { ...match.date, $lte: new Date(endDate) };

    const analytics = await Attendance.aggregate([
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
    res.status(500).json({ error: err.message });
  }
});

// Test ping
app.get('/api/ping', (req, res) => {
  res.status(200).json({ message: '✅ Backend is running!' });
});

// Setup admin
app.post('/api/setup/admin', async (req, res) => {
  try {
    const { login, password, fullName } = req.body;
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
    res.status(500).json({ error: err.message });
  }
});

// ✅ Обновление пользователя (head/admin)
app.put('/api/admin/users/:id', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const { login, fullName, role, password } = req.body;

    const updateData = {};
    if (login) updateData.login = login;
    if (fullName) updateData.fullName = fullName;
    if (role) updateData.role = role;
    if (password) updateData.password = bcrypt.hashSync(password, 10); // если передан новый пароль — хешируем

    const updatedUser = await User.findByIdAndUpdate(req.params.id, updateData, { new: true }).select('-password');
    if (!updatedUser) return res.status(404).json({ error: 'User not found' });

    res.status(200).json(updatedUser);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));

