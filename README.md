```markdown
# 📊 Attendance System — Flutter Web + Express.js + MongoDB

Система учёта посещаемости студентов, разработанная на **Flutter Web** (frontend) с backend на **Express.js** и базой данных **MongoDB**.


---

## ⚡️ Функциональность

### 👨‍🏫 Преподаватель
- Авторизация
- Просмотр списка групп
- Отметка посещаемости студентов
- Просмотр аналитики по посещаемости

### 🧑‍💼 Заведующий
- Все возможности преподавателя
- Управление пользователями (создание / удаление)
- Управление группами и студентами
- Управление предметами
- Расширенная аналитика

---

## 🖥 Backend (Express.js + MongoDB)

### 📁 Структура `backend/`

```

backend/
├── server.js
├── package.json
├── .env
└── ...

````

### 📦 Установка зависимостей

```bash
cd backend
npm install
````

### ⚙️ Пример `.env`

```env
PORT=5000
MONGO_URI=mongodb+srv://USERNAME:PASSWORD@cluster.mongodb.net/?retryWrites=true&w=majority
```

### 🚀 Запуск сервера

```bash
npm run dev
```

или

```bash
node server.js
```

После запуска:

```
🚀 Сервер запущен на порту 5000
✅ MongoDB подключена
```

Тестовый маршрут:

```
GET http://localhost:5000/api/ping
```

Ответ:

```json
{ "message": "✅ Backend работает!" }
```

---

## 🌐 Frontend (Flutter Web)

### 📥 Установка зависимостей

```bash
cd frontend
flutter pub get
```

### 🧪 Запуск в режиме разработки

```bash
flutter run -d chrome
```

### 🏗 Сборка production версии

```bash
flutter build web
```

Результат будет в папке:

```
frontend/build/web/
```

---

## 🔗 Подключение к Backend

В файле `frontend/lib/services/api_service.dart` укажи адрес backend:

```dart
static const String baseUrl = 'http://localhost:5000/api';
```

При деплое на сервер:

```dart
static const String baseUrl = 'https://your-domain.com/api';
```

---

## 🧠 Локальное хранилище (Hive)

Используется **Hive** для:

* хранения токена
* хранения текущего пользователя
* кеширования групп, студентов и посещаемости
* работы в офлайн-режиме при необходимости

📁 `frontend/lib/services/hive_service.dart` — отвечает за кэш и чтение локальных данных.

---

## 🛢 База данных (MongoDB)

Используемые коллекции:

* `users` — пользователи
* `students` — студенты
* `groups` — группы
* `subjects` — предметы
* `attendance` — посещаемость

---

## 🧰 Используемые технологии

### Frontend

* [Flutter Web](https://flutter.dev/)
* [Provider](https://pub.dev/packages/provider)
* [Hive](https://pub.dev/packages/hive)
* [Material 3](https://m3.material.io/)

### Backend

* [Node.js](https://nodejs.org/)
* [Express.js](https://expressjs.com/)
* [Mongoose](https://mongoosejs.com/)
* [dotenv](https://www.npmjs.com/package/dotenv)
* [CORS](https://www.npmjs.com/package/cors)

---

## 📝 Пример рабочего флоу

```bash
# 1. Запустить backend
cd backend
npm run dev

# 2. Проверить работу API
# http://localhost:5000/api/ping

# 3. Запустить frontend
cd frontend
flutter run -d chrome

# 4. Авторизоваться — данные кэшируются в Hive
# 5. При следующем входе — пользователь восстанавливается из кэша
```

---

## 🚀 План на будущее

* JWT аутентификация с refresh токенами
* Защита маршрутов и роли пользователей
* Docker для развёртывания
* CI/CD и деплой на сервер

---

## 🧾 Git команды

```bash
# Клонировать проект
git clone https://github.com/your-repo/attendance-system.git

# Создать новую ветку
git checkout -b feature/express-setup

# Добавить изменения
git add .

# Сделать коммит
git commit -m "Подключил Express и базу MongoDB"

# Отправить в репозиторий
git push origin feature/express-setup
```

---

## 📄 Лицензия

MIT License © 2025 — Attendance System Project

```
```
