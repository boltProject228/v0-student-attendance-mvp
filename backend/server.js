const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const path = require('path');
const dotenv = require('dotenv');
const morgan = require('morgan');
const chalk = require('chalk');
const luxon = require('luxon');
const exceljs = require('exceljs');

dotenv.config({ path: path.resolve(__dirname, '.env') });

const app = express();
app.use(cors());
// Увеличение лимита для обработки больших данных
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

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
    } else if (status === 304) {
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

// Определение схем с индексами
const userSchema = new mongoose.Schema({
  login: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['teacher', 'head', 'admin'], default: 'teacher' },
  fullName: { type: String },
  createdAt: { type: Date, default: Date.now },
});
const User = mongoose.model('User', userSchema);

const groupSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  specialty: { type: String, required: true },
  course: { type: Number, required: true },
  createdAt: { type: Date, default: Date.now },
});
const Group = mongoose.model('Group', groupSchema);

const studentSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  groupId: { type: String, ref: 'Group.id', required: true },
  createdAt: { type: Date, default: Date.now },
});
// Создание уникального индекса на fullName и groupId
studentSchema.index({ fullName: 1, groupId: 1 }, { unique: true });
const Student = mongoose.model('Student', studentSchema);

const attendanceSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  groupId: { type: String, ref: 'Group.id', required: true },
  date: { type: Date, required: true },
  status: { type: String, enum: ['present', 'absent', 'sick', 'ithub'], required: true },
  updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});
const Attendance = mongoose.model('Attendance', attendanceSchema);

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

app.get('/api/admin/users', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const users = await User.find().select('-password');
    res.set('Cache-Control', 'no-store');
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

app.put('/api/admin/users/:id', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const { fullName, login, role, password } = req.body;
    const updateData = { fullName, login, role };
    
    if (password) {
      updateData.password = bcrypt.hashSync(password, 10);
    }

    const updated = await User.findByIdAndUpdate(
      req.params.id, 
      updateData, 
      { new: true, runValidators: true }
    );

    if (!updated) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const userResponse = updated.toObject();
    delete userResponse.password;

    res.status(200).json(userResponse);
  } catch (err) {
    console.error('User update error:', err);
    if (err.code === 11000) {
      return res.status(400).json({ error: 'Login is already taken' });
    }
    res.status(500).json({ error: err.message });
  }
});

// Update /api/groups to return _id
app.get('/api/groups', authenticate, async (req, res) => {
  try {
    const groups = await Group.find().select('-__v');
    const transformedGroups = groups.map(group => ({
      id: group.id, // Используем кастомное поле id
      name: group.name,
      specialty: group.specialty,
      course: group.course,
      createdAt: group.createdAt,
    }));
    res.set('Cache-Control', 'no-store');
    res.status(200).json(transformedGroups); // Явная сериализация в JSON
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// Update /api/admin/groups to return _id
app.get('/api/admin/groups', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const groups = await Group.find().select('-__v'); // Removed -_id
    res.set('Cache-Control', 'no-store');
    res.status(200).json(groups);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
app.post('/api/admin/groups', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const { id, name, specialty, course } = req.body;
    const group = new Group({ id, name, specialty, course });
    await group.save();
    res.status(201).json(group.toObject({ transform: (doc, ret) => {
      delete ret._id;
      delete ret.__v;
      return ret;
    } }));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/admin/groups/:id', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const deleted = await Group.findOneAndDelete({ id: req.params.id });
    if (!deleted) return res.status(404).json({ error: 'Group not found' });
    res.status(200).json({ message: 'Group deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update /api/admin/students to return _id
app.get('/api/admin/students', authenticate, isHeadOrAdmin, async (req, res) => {
  console.log('Request to /api/admin/students received');
  try {
    const students = await Student.find().select('-__v'); // Removed -_id
    res.set('Cache-Control', 'no-store');
    res.status(200).json(students);
  } catch (err) {
    console.error('Error fetching students:', err);
    res.status(500).json({ error: err.message });
  }
});

// Public students endpoint
app.get('/api/students', authenticate, async (req, res) => {
  try {
    const students = await Student.find().select('-__v'); // Keep _id
    res.set('Cache-Control', 'no-store');
    res.status(200).json(students);
  } catch (err) {
    console.error('Error fetching students (public):', err);
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/admin/students', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const { fullName, groupId } = req.body;
    const group = await Group.findOne({ id: groupId });
    if (!group) return res.status(404).json({ error: 'Group not found' });
    const student = new Student({ fullName, groupId: group.id });
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

app.get('/api/attendance', authenticate, async (req, res) => {
  try {
    const { groupId, date } = req.query;
    const filter = {};
    if (groupId) filter.groupId = groupId;
    if (date) {
      const start = new Date(date + 'T00:00:00.000Z');
      const end = new Date(start);
      end.setUTCDate(end.getUTCDate() + 1);
      filter.date = { $gte: start, $lt: end };
    }
    const attendance = await Attendance.find(filter).populate('updatedBy', 'fullName role').populate('studentId', 'fullName');
    res.set('Cache-Control', 'no-store');
    res.status(200).json(attendance);
  } catch (err) {
    console.error('Attendance fetch error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/attendance', authenticate, async (req, res) => {
  try {
    const { studentId, groupId, date, status } = req.body;
    const attendance = new Attendance({ studentId, groupId, date: new Date(date), status, updatedBy: req.user.id });
    await attendance.save();
    res.status(201).json(attendance);
  } catch (err) {
    console.error('Attendance create error:', err);
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
    console.error('Attendance update error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/attendance/:id', authenticate, async (req, res) => {
  try {
    const deleted = await Attendance.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Attendance not found' });
    res.status(200).json({ message: 'Attendance deleted' });
  } catch (err) {
    console.error('Attendance delete error:', err);
    res.status(500).json({ error: err.message });
  }
});

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
    res.set('Cache-Control', 'no-store');
    res.status(200).json(stats);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/analytics/group/:groupId', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const { groupId } = req.params;
    const { startDate, endDate, period = 'day' } = req.query;

    if (!groupId) {
      return res.status(400).json({ error: 'Invalid group ID' });
    }

    if (!startDate || !endDate) {
      return res.status(400).json({ error: 'startDate and endDate are required' });
    }

    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setDate(end.getDate() + 1);

    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
      return res.status(400).json({ error: 'Invalid date format' });
    }

    const group = await Group.findOne({ id: groupId });
    if (!group) return res.status(404).json({ error: 'Group not found' });

    const students = await Student.find({ groupId: group.id });
    const studentIds = students.map(s => s._id);

    const matchStage = {
      groupId: group.id,
      date: { $gte: start, $lt: end },
      status: { $in: ['present', 'absent', 'sick', 'ithub'] },
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
          attendancePercentage: { $multiply: [{ $divide: ['$totalPresent', { $max: ['$totalDays', 1] }] }, 100] },
          periods: 1
        }
      },
      { $lookup: { from: 'students', localField: 'studentId', foreignField: '_id', as: 'student' } },
      { $unwind: '$student' },
      { $sort: { 'student.fullName': 1 } }
    ]);

    res.set('Cache-Control', 'no-store');
    res.status(200).json(aggregation);
  } catch (err) {
    console.error('Group analytics error:', err);
    res.status(500).json({ error: err.message });
  }
});

const holidays = [
  '2025-01-01', '2025-03-08', '2025-03-21', '2025-03-22', '2025-05-07', '2025-05-09',
  '2025-07-06', '2025-12-16'
];

app.post('/api/admin/import', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const { students } = req.body;
    if (!Array.isArray(students)) return res.status(400).json({ error: 'Students must be an array' });

    let importedStudents = 0;
    const errors = []; // Массив для хранения ошибок

    // Обработка данных частями для оптимизации
    for (let i = 0; i < students.length; i += 100) {
      const batch = students.slice(i, i + 100);
      const operations = [];

      for (const student of batch) {
        const { fullName, groupId } = student;
        if (!fullName || !groupId) {
          errors.push({ fullName, groupId, error: 'Missing fullName or groupId' });
          continue;
        }

        try {
          const group = await Group.findOne({ id: groupId });
          if (!group) {
            errors.push({ fullName, groupId, error: `Group ${groupId} not found` });
            continue;
          }

          operations.push({
            updateOne: {
              filter: { fullName, groupId: group.id },
              update: { $setOnInsert: { fullName, groupId: group.id, createdAt: new Date() } },
              upsert: true
            }
          });
        } catch (err) {
          errors.push({ fullName, groupId, error: err.message });
        }
      }

      if (operations.length > 0) {
        const result = await Student.bulkWrite(operations);
        importedStudents += result.upsertedCount || 0; // Учитываем только новые записи
      }
    }

    // Формируем ответ
    if (errors.length > 0) {
      res.status(207).json({
        importedStudents,
        errors,
        message: 'Import completed with errors'
      });
    } else {
      res.status(200).json({ importedStudents, message: 'Import successful' });
    }
  } catch (err) {
    console.error('Import error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/export/excel', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const { groupId, startDate, endDate } = req.query;
    if (!groupId || !startDate || !endDate) return res.status(400).json({ error: 'Required params missing' });

    const group = await Group.findOne({ id: groupId });
    if (!group) return res.status(404).json({ error: 'Group not found' });

    const students = await Student.find({ groupId: group.id }).sort('fullName');
    if (students.length === 0) return res.status(404).json({ error: 'No students' });

    const start = new Date(startDate);
    const end = new Date(endDate);
    const allDates = [];
    let current = new Date(start);
    while (current <= end) {
      allDates.push(new Date(current));
      current.setDate(current.getDate() + 1);
    }

    const attendances = await Attendance.find({
      groupId: group.id,
      date: { $gte: start, $lte: end }
    }).populate('updatedBy', 'fullName');

    const workbook = new exceljs.Workbook();
    const sheet = workbook.addWorksheet('Посещаемость');

    sheet.getRow(1).getCell(1).value = 'СТУДЕНТЫ';
    sheet.getCell('B1').value = 'ПОСЕЩАЕМОСТЬ';
    sheet.mergeCells('B1:' + String.fromCharCode(65 + allDates.length + 3) + '1');

    sheet.getRow(2).getCell(2).value = 'ДАТА';
    allDates.forEach((date, index) => {
      const label = luxon.DateTime.fromJSDate(date).toFormat('dd.MM') + (isNonWorkingDay(date) ? ' (Выходной)' : '');
      sheet.getRow(2).getCell(index + 3).value = label;
    });
    sheet.getRow(2).getCell(allDates.length + 3).value = '% Посещаемости';
    sheet.getRow(2).getCell(allDates.length + 4).value = 'Обновил';

    students.forEach((student, sIndex) => {
      const rowNum = sIndex + 3;
      const row = sheet.getRow(rowNum);
      row.getCell(1).value = student.fullName;
      row.getCell(2).value = group.name;

      let attended = 0;
      let totalRelevant = 0;

      allDates.forEach((date, dIndex) => {
        const cell = row.getCell(dIndex + 3);
        const att = attendances.find(a => a.studentId.toString() === student._id.toString() && a.date.toDateString() === date.toDateString());
        let statusChar = '';
        let fillColor = 'FFFFFF';

        if (isNonWorkingDay(date)) {
          fillColor = 'D3D3D3';
        } else if (att) {
          switch (att.status) {
            case 'present':
              statusChar = 'П';
              fillColor = '90EE90';
              attended++;
              totalRelevant++;
              break;
            case 'absent':
              statusChar = 'О';
              fillColor = 'FF0000';
              totalRelevant++;
              break;
            case 'sick':
              statusChar = 'Б';
              fillColor = 'FFFF00';
              break;
            case 'ithub':
              statusChar = 'IT';
              fillColor = '0000FF';
              attended++;
              totalRelevant++;
              break;
          }
        } else {
          statusChar = 'О';
          fillColor = 'FF0000';
          totalRelevant++;
        }

        cell.value = statusChar;
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: fillColor } };
      });

      const pct = totalRelevant > 0 ? ((attended / totalRelevant) * 100).toFixed(1) + '%' : '0%';
      row.getCell(allDates.length + 3).value = pct;

      const lastAtt = attendances.filter(a => a.studentId.toString() === student._id.toString()).sort((a, b) => b.updatedAt - a.updatedAt)[0];
      row.getCell(allDates.length + 4).value = lastAtt ? lastAtt.updatedBy.fullName : '';
    });

    const avgRow = sheet.getRow(students.length + 3);
    avgRow.getCell(1).value = 'Итог по группе';

    let groupAttended = 0;
    let groupTotal = 0;

    allDates.forEach((date, dIndex) => {
      if (isNonWorkingDay(date)) return;

      let dayAttended = 0;
      let dayTotal = 0;

      students.forEach(student => {
        const att = attendances.find(a => a.studentId.toString() === student._id.toString() && a.date.toDateString() === date.toDateString());
        if (att) {
          if (['present', 'ithub'].includes(att.status)) dayAttended++;
          if (att.status !== 'sick') dayTotal++;
        } else {
          dayTotal++;
        }
      });

      const dayPct = dayTotal > 0 ? ((dayAttended / dayTotal) * 100).toFixed(1) + '%' : '0%';
      avgRow.getCell(dIndex + 3).value = dayPct;

      groupAttended += dayAttended;
      groupTotal += dayTotal;
    });

    const groupPct = groupTotal > 0 ? ((groupAttended / groupTotal) * 100).toFixed(1) + '%' : '0%';
    avgRow.getCell(allDates.length + 3).value = groupPct;

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename=attendance_export.xlsx');
    await workbook.xlsx.write(res);
    res.end();
  } catch (err) {
    console.error('Export error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/test/excel', async (req, res) => {
  try {
    const workbook = new exceljs.Workbook();
    const sheet = workbook.addWorksheet('Test');

    sheet.getRow(1).values = ['СТУДЕНТЫ', 'ПОСЕЩАЕМОСТЬ'];
    sheet.getRow(2).values = ['', 'ДАТА', '01.10', '02.10', '03.10', '04.10', '05.10'];

    const students = ['Student1 Group1', 'Student2 Group1', 'Student3 Group2'];
    const statuses = ['П', 'О', 'Б', 'IT', ''];

    students.forEach((s, index) => {
      const row = sheet.getRow(index + 3);
      const [fullName, group] = s.split(' ');
      row.values = [fullName, group, ...Array.from({ length: 5 }, () => statuses[Math.floor(Math.random() * statuses.length)])];
    });

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename=test_attendance.xlsx');
    await workbook.xlsx.write(res);
    res.end();
  } catch (err) {
    console.error('Test Excel error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/analytics/full', authenticate, isHeadOrAdmin, async (req, res) => {
  try {
    const { groupId, course, startDate, endDate } = req.query;

    const match = { status: { $in: ['present', 'absent', 'sick', 'ithub'] } };

    if (startDate) match.date = { $gte: new Date(startDate) };
    if (endDate) match.date = { ...match.date, $lte: new Date(endDate) };
    if (groupId) match.groupId = groupId;

    const aggregation = await Attendance.aggregate([
      { $match: match },
      { $addFields: { dayOfWeek: { $dayOfWeek: '$date' } } },
      { $match: { dayOfWeek: { $gte: 2, $lte: 6 } } },
      { $addFields: { dateStr: { $dateToString: { format: '%Y-%m-%d', date: '$date' } } } },
      { $match: { dateStr: { $not: { $in: holidays } } } },
      {
        $group: {
          _id: '$studentId',
          present: { $sum: { $cond: [{ $eq: ['$status', 'present'] }, 1, 0] } },
          absent: { $sum: { $cond: [{ $eq: ['$status', 'absent'] }, 1, 0] } },
          sick: { $sum: { $cond: [{ $eq: ['$status', 'sick'] }, 1, 0] } },
          ithub: { $sum: { $cond: [{ $eq: ['$status', 'ithub'] }, 1, 0] } },
          groupId: { $first: '$groupId' }
        }
      },
      { $lookup: { from: 'students', localField: '_id', foreignField: '_id', as: 'student' } },
      { $unwind: '$student' },
      { $lookup: { from: 'groups', localField: 'groupId', foreignField: 'id', as: 'group' } },
      { $unwind: '$group' },
      ...(course ? [{ $match: { 'group.course': parseInt(course) } }] : []),
      {
        $project: {
          studentId: '$_id',
          fullName: '$student.fullName',
          attendancePercentage: {
            $cond: [
              { $eq: [{ $add: ['$present', '$ithub', '$absent'] }, 0] },
              0,
              { $multiply: [{ $divide: [{ $add: ['$present', '$ithub'] }, { $add: ['$present', '$ithub', '$absent'] }] }, 100] }
            ]
          },
          statuses: {
            present: '$present',
            absent: '$absent',
            sick: '$sick',
            ithub: '$ithub'
          },
          groupId: '$group.id',
          groupName: '$group.name',
          course: '$group.course'
        }
      },
      {
        $group: {
          _id: '$groupId',
          groupName: { $first: '$groupName' },
          course: { $first: '$course' },
          students: { $push: { fullName: '$fullName', attendancePercentage: '$attendancePercentage', statuses: '$statuses' } },
          groupPresent: { $sum: { $add: ['$present', '$ithub'] } },
          groupTotal: { $sum: { $add: ['$present', '$ithub', '$absent'] } }
        }
      },
      {
        $project: {
          groupId: '$_id',
          groupName: 1,
          groupAttendance: {
            $cond: [
              { $eq: ['$groupTotal', 0] },
              0,
              { $multiply: [{ $divide: ['$groupPresent', '$groupTotal' ]}, 100] }
            ]
          },
          students: 1,
          course: 1
        }
      },
      {
        $group: {
          _id: '$course',
          groups: { $push: { groupId: '$groupId', groupName: '$groupName', groupAttendance: '$groupAttendance', students: '$students' } },
          coursePresent: { $sum: '$groupPresent' },
          courseTotal: { $sum: '$groupTotal' }
        }
      },
      {
        $project: {
          course: '$_id',
          averageAttendance: {
            $cond: [
              { $eq: ['$courseTotal', 0] },
              0,
              { $multiply: [{ $divide: ['$coursePresent', '$courseTotal'] }, 100] }
            ]
          },
          groups: 1
        }
      },
      { $sort: { course: 1 } }
    ]);

    res.set('Cache-Control', 'no-store');
    res.status(200).json({ courses: aggregation });
  } catch (err) {
    console.error('Full analytics error:', err);
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

function isNonWorkingDay(date) {
  const dateStr = date.toISOString().split('T')[0];
  return date.getDay() === 0 || date.getDay() === 6 || holidays.includes(dateStr);
}