<div align="center">

# 🖥️ RDS & FSLogix Control Center
### Universal Multi-Farm Remote Desktop & FSLogix Profile Container Management Tool

![Version](https://img.shields.io/badge/version-4.2.0_Dark_Edition-38bdf8?style=for-the-badge)
![Platform](https://img.shields.io/badge/platform-Windows_Server_%7C_10_%7C_11-0ea5e9?style=for-the-badge)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-2563eb?style=for-the-badge&logo=powershell&logoColor=white)
![FSLogix](https://img.shields.io/badge/FSLogix-Linux_Samba_SSH-9333ea?style=for-the-badge&logo=linux&logoColor=white)

**[ 🇷🇺 Русская документация](#-возможности-ru) &nbsp;|&nbsp; [ 🇬🇧 English Documentation](#-features-en)**

</div>

---

## 🇷🇺 Возможности (RU)

**RDS & FSLogix Control Center** — универсальное десктопное приложение с современным темным интерфейсом (DWM Dark UI) для централизованного мониторинга и администрирования распределенных ферм **Microsoft Remote Desktop Services (RDS)** и файловых серверов хранения контейнеров профилей **FSLogix (Linux / Samba)**.

### ⌨️ Горячие клавиши (Hotkeys v4.2)

| Клавиша | Действие |
| :--- | :--- |
| **`F2`** | ▣ Теневое подключение: **Управление** (без запроса согласия) |
| **`F3`** | ◉ Теневое подключение: **Наблюдение** (без запроса согласия) |
| **`F4`** | ◈ Управление узлами сеансов **RDSH (Drain Mode)** |
| **`F5`** | ⟳ **Обновить** список сессий со всех ферм |
| **`F6`** | ★ Управление доступом к **Коллекциям (Доменные группы AD)** |
| **`F7`** | ⚡ Менеджер блокировок профилей **FSLogix (VHDX)** |
| **`F8`** | ⚙ Диспетчер **Процессов** выбранной сессии |
| **`F9`** | ✉ Отправить **Сообщение** выбранным пользователям |
| **`F10`** | ⏸ **Отключить** выбранные сеансы (Disconnect) |
| **`F11`** | ✖ **Сбросить** выбранные сеансы (Logoff) |
| **`F12`** | ⚙ **Настройки** инфраструктуры (список брокеров RDS и сервер FSLogix) |
| **`Ctrl + S`** | ⤓ Экспорт текущей таблицы сессий в **CSV** |
| **`Ctrl + F`** | Фокус в поле **Поиска** (`Esc` — очистить фильтр) |

---

## 🇬🇧 Features & Hotkeys (EN)

| Shortcut | Action |
| :--- | :--- |
| **`F2` / `F3`** | Silent Shadowing: **Control** (`F2`) or **View-Only** (`F3`) with zero user prompt |
| **`F4`** | **RDSH Node Drain Mode** manager (`Yes` / `NotUntilReboot` / `No`) |
| **`F5`** | Asynchronous multi-broker **Session Refresh** |
| **`F6`** | **RDS Collection User Groups** access management (AD group picker) |
| **`F7`** | **FSLogix VHDX Lock Manager** over SSH (`smbstatus` / `kill -9`) |
| **`F8`** | **Per-Session Task Manager** (view RAM usage & terminate hung apps) |
| **`F9` / `F10` / `F11`** | **Send Message** (`F9`), **Disconnect** (`F10`), **Force Logoff** (`F11`) |
| **`F12`** | **Infrastructure Settings** & Active Directory Broker Auto-Discovery |
| **`Ctrl + S` / `Ctrl + F`** | **Export to CSV** (`Ctrl+S`) / **Focus Search Box** (`Ctrl+F`) |
