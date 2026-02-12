# Attendance System - Flutter Web App

Система учёта посещаемости студентов, разработанная на Flutter для веб-платформы.

## Структура проекта

```
lib/
├── main.dart                 # Точка входа приложения
├── models/                   # Модели данных
│   ├── user.dart
│   ├── student.dart
│   ├── group.dart
│   ├── subject.dart
│   └── attendance.dart
├── services/                 # Сервисы
│   ├── api_service.dart      # API клиент для связи с backend
│   └── storage_service.dart  # Локальное хранилище
├── providers/                # State management (Provider)
│   ├── auth_provider.dart
│   ├── attendance_provider.dart
│   ├── groups_provider.dart
│   └── admin_provider.dart
├── screens/                  # Экраны приложения
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── attendance_screen.dart
│   ├── groups_screen.dart
│   ├── admin_screen.dart
│   └── analytics_screen.dart
└── widgets/                  # Переиспользуемые компоненты
    └── app_drawer.dart
```

## Функциональность

### Для преподавателей:
- Авторизация в системе
- Просмотр списка групп
- Отметка посещаемости студентов
- Просмотр аналитики по посещаемости

### Для завкафедры:
- Все функции преподавателя
- Управление пользователями (создание, удаление)
- Управление группами (создание, удаление)
- Управление студентами (создание, удаление)
- Управление предметами (создание, удаление)
- Расширенная аналитика

## Установка и запуск

### Требования:
- Flutter SDK 3.0.0+
- Dart SDK 3.0.0+

### Установка зависимостей:
```bash
flutter pub get
```

### Запуск в режиме разработки:
```bash
flutter run -d chrome
```

### Сборка для production:
```bash
flutter build web
```

Собранные файлы будут находиться в папке `build/web/`

## Подключение к Backend

Backend API должен быть запущен на `http://localhost:3000/api`

Для изменения адреса API отредактируйте файл `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://your-api-url/api';
```

## База данных

Приложение использует существующую MongoDB базу данных через API:
- Users (пользователи)
- Students (студенты)
- Groups (группы)
- Subjects (предметы)
- Attendance (посещаемость)

## Технологии

- **Flutter** - UI фреймворк
- **Provider** - State management
- **HTTP** - API клиент
- **SharedPreferences** - Локальное хранилище
- **Material Design 3** - Дизайн система
