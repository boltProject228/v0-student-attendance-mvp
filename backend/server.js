// server.js (Полная версия с исправлениями кэширования и даты)

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
    } else if (status === 304) { // Добавим 304 для наглядности, хотя теперь они не должны появляться
      emoji = '♻️';
      color = chalk.cyan;
    }

    const timestamp = new Date().toISOString().replace('T', ' ').replace('Z', '').split('.')[0];
    const log = `[${timestamp}] ${tokens.method(req, res)} ${tokens.url(req, res)}${tokens.body(req, res)} ${emoji} ${status} - ${tokens['response-time'](req, res)}ms`;
    return color(log);
  })
);

console.log('📡 MONGO_URL:', process.env.MONGO_URL || 'No MONGO_URL provided');

mongoose
  .connect(process.env.MONGO_URL, {
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000,
  })
  .then(() => console.log('✅ MongoDB connected successfully'))
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err.message);
    process.exit(1);
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
    res.set('Cache-Control', 'no-store'); // ⬅️ ИСПРАВЛЕНО: Отключение кэширования
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

// 🚀 НОВЫЙ МАРШРУТ: PUT (Обновление пользователя)
app.put('/api/admin/users/:id', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const { fullName, login, role, password } = req.body;
    const updateData = { fullName, login, role };
    
    // Если в теле запроса передан новый пароль, его нужно хешировать
    if (password) {
      updateData.password = bcrypt.hashSync(password, 10);
    }

    const updated = await User.findByIdAndUpdate(
      req.params.id, 
      updateData, 
      { new: true, runValidators: true } // `new: true` возвращает обновленный документ; `runValidators: true` проверяет схему
    );

    if (!updated) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Возвращаем обновленного пользователя, исключая пароль
    const userResponse = updated.toObject();
    delete userResponse.password;

    res.status(200).json(userResponse);
  } catch (err) {
    console.error('User update error:', err);
    // Обработка ошибки уникальности (например, если логин уже занят)
    if (err.code === 11000) {
      return res.status(400).json({ error: 'Login is already taken' });
    }
    res.status(500).json({ error: err.message });
  }
});


// Group CRUD
app.get('/api/groups', authenticate, async (req, res) => {
  try {
    const groups = await Group.find();
    res.set('Cache-Control', 'no-store'); // ⬅️ ИСПРАВЛЕНО: Отключение кэширования
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
    res.set('Cache-Control', 'no-store'); // ⬅️ ИСПРАВЛЕНО: Отключение кэширования
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
    if (date) {
      // ⬅️ ИСПРАВЛЕНО: Нормализация даты к началу дня UTC
      const start = new Date(date + 'T00:00:00.000Z'); 
      const end = new Date(start);
      end.setUTCDate(end.getUTCDate() + 1);
      filter.date = { $gte: start, $lt: end };
    }
    const attendance = await Attendance.find(filter).populate('updatedBy', 'fullName role');
    res.set('Cache-Control', 'no-store'); // ⬅️ ИСПРАВЛЕНО: Отключение кэширования
    res.status(200).json(attendance);
  } catch (err) {
    console.error('Attendance fetch error:', err); // Лог для дебага
    res.status(500).json({ error: err.message });
  }
});

// В post/put/delete добавлен console.error при catch для дебага
app.post('/api/attendance', authenticate, async (req, res) => {
  try {
    const attendance = new Attendance({ ...req.body, updatedBy: req.user.id });
    await attendance.save();
    res.status(201).json(attendance);
  } catch (err) {
    console.error('Attendance create error:', err); // Лог
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/attendance/:id', authenticate, async (req, res) => {
  try {
    const existing = await Attendance.findById(req.params.id);
    if (!existing) return res.status(404).json({ error: 'Attendance not found' });
    if (req.body.updatedAt && new Date(req.body.updatedAt) < existing.updatedAt) {
      return res.status(409).json({ error: 'Conflict: Record was updated by another user' });
    }
    const updated = await Attendance.findByIdAndUpdate(
      req.params.id,
      { ...req.body, updatedBy: req.user.id, updatedAt: Date.now() },
      { new: true }
    );
    res.status(200).json(updated);
  } catch (err) {
    console.error('Attendance update error:', err); // Лог
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/attendance/:id', authenticate, async (req, res) => {
  try {
    const deleted = await Attendance.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Attendance not found' });
    res.status(200).json({ message: 'Attendance deleted' });
  } catch (err) {
    console.error('Attendance delete error:', err); // Лог
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
      { 
        $addFields: {
          dayOfWeek: { $dayOfWeek: '$date' } 
        }
      },
      { 
        $match: {
          dayOfWeek: { $gte: 2, $lte: 6 } 
        }
      },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]);

    let presentCount = analytics.find((a) => a._id === 'present')?.count || 0;
    let absentCount = analytics.find((a) => a._id === 'absent')?.count || 0;
    let sickCount = analytics.find((a) => a._id === 'sick')?.count || 0;
    let ithubCount = analytics.find((a) => a._id === 'ithub')?.count || 0;

    const totalAttend = presentCount + absentCount + ithubCount || 1;
    const total = totalAttend + sickCount || 1;

    const stats = {
      averagePresent: ((presentCount + ithubCount) / totalAttend * 100).toFixed(1),
      averageAbsent: (absentCount / totalAttend * 100).toFixed(1),
      averageSick: (sickCount / total * 100).toFixed(1),
      averageIThub: (ithubCount / totalAttend * 100).toFixed(1),
      totalStudents: await Student.countDocuments(),
      totalGroups: await Group.countDocuments(),
    };
    res.set('Cache-Control', 'no-store'); // ⬅️ ИСПРАВЛЕНО: Отключение кэширования
    res.status(200).json(stats);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Group analytics
app.get('/api/analytics/group/:groupId', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const { groupId } = req.params;
    const { startDate, endDate, period = 'day' } = req.query;

    if (!mongoose.Types.ObjectId.isValid(groupId)) {
      return res.status(400).json({ error: 'Invalid group ID' });
    }

    if (!startDate || !endDate) {
      return res.status(400).json({ error: 'startDate and endDate are required' });
    }

    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setDate(end.getDate() + 1); // Include endDate

    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
      return res.status(400).json({ error: 'Invalid date format' });
    }

    // Validate group
    const group = await Group.findById(groupId);
    if (!group) return res.status(404).json({ error: 'Group not found' });

    // Get students in group
    const students = await Student.find({ groupId });
    const studentIds = students.map(s => s._id);

    // Aggregate attendance
    const matchStage = {
      groupId: new mongoose.Types.ObjectId(groupId),
      date: { $gte: start, $lt: end },
      status: { $in: ['present', 'absent', 'sick', 'ithub'] }, // Exclude unmarked
    };

    const groupBy = period === 'day' ? {
      $dateToString: { format: '%Y-%m-%d', date: '$date' }
    } : period === 'week' ? {
      $concat: [
        { $dateToString: { format: '%Y', date: '$date' } },
        '-W',
        { $toString: { $isoWeek: '$date' } }
      ]
    } : {
      $dateToString: { format: '%Y-%m', date: '$date' }
    };

    const aggregation = await Attendance.aggregate([
      { 
        $match: matchStage
      },
      { 
        $addFields: {
          dayOfWeek: { $dayOfWeek: '$date' } 
        }
      },
      { 
        $match: {
          dayOfWeek: { $gte: 2, $lte: 6 } 
        }
      },
      {
        $group: {
          _id: {
            studentId: '$studentId',
            period: groupBy
          },
          statuses: { $push: '$status' },
          presentCount: {
            $sum: { $cond: [{ $in: ['$status', ['present', 'ithub']] }, 1, 0] }
          },
          totalCount: { 
            $sum: { $cond: [{ $ne: ['$status', 'sick'] }, 1, 0] } 
          }
        }
      },
      {
        $group: {
          _id: '$_id.studentId',
          periods: {
            $push: {
              period: '$_id.period',
              presentCount: '$presentCount',
              totalCount: '$totalCount',
              statuses: '$statuses'
            }
          },
          totalPresent: { $sum: '$presentCount' },
          totalDays: { $sum: '$totalCount' }
        }
      },
      {
        $project: {
          studentId: '$_id',
          attendancePercentage: {
            $cond: [
              { $eq: ['$totalDays', 0] },
              0,
              { $multiply: [{ $divide: ['$totalPresent', '$totalDays'] }, 100] }
            ]
          },
          periods: 1,
          totalPresent: 1,
          totalDays: 1
        }
      }
    ]);

    // Group stats
    const totalPresent = aggregation.reduce((sum, s) => sum + s.totalPresent, 0);
    const totalDays = aggregation.reduce((sum, s) => sum + s.totalDays, 0);
    const groupPercentage = totalDays > 0 ? (totalPresent / totalDays) * 100 : 0;

    // Map student data
    const studentStats = aggregation.map(s => ({
      studentId: s.studentId.toString(),
      fullName: students.find(st => st._id.toString() === s.studentId.toString())?.fullName || 'Unknown',
      attendancePercentage: s.attendancePercentage.toFixed(2),
      periods: s.periods.map(p => ({
        period: p.period,
        percentage: p.totalCount > 0 ? ((p.presentCount / p.totalCount) * 100).toFixed(2) : 0,
        statuses: p.statuses
      }))
    }));

    res.set('Cache-Control', 'no-store'); // ⬅️ ИСПРАВЛЕНО: Отключение кэширования
    res.status(200).json({
      groupId,
      groupName: group.name,
      groupPercentage: groupPercentage.toFixed(2),
      students: studentStats
    });
  } catch (err) {
    console.error('Analytics error:', err);
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

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));