// server.js
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const path = require("path");

// 📌 Загружаем .env из корня проекта
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const app = express();
app.use(cors());
app.use(express.json());

// ✅ Проверим, что переменная загрузилась
console.log("📡 MONGO_URI из .env:", process.env.MONGO_URI);

// Подключение к MongoDB
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("✅ MongoDB подключена"))
  .catch((err) => console.error("❌ Ошибка MongoDB:", err));

// Простой тестовый маршрут
app.get("/api/ping", (req, res) => {
  res.json({ message: "✅ Backend работает!" });
});

// Запуск сервера
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Сервер запущен на порту ${PORT}`));
