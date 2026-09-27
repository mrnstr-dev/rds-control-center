<div align="center">

# 🖥️ RDS & FSLogix Control Center
### Universal Multi-Farm Remote Desktop & FSLogix Profile Container Management Tool

![Version](https://img.shields.io/badge/version-4.0.0_Dark_Edition-38bdf8?style=for-the-badge)
![Platform](https://img.shields.io/badge/platform-Windows_Server_%7C_10_%7C_11-0ea5e9?style=for-the-badge)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-2563eb?style=for-the-badge&logo=powershell&logoColor=white)
![FSLogix](https://img.shields.io/badge/FSLogix-Linux_Samba_SSH-9333ea?style=for-the-badge&logo=linux&logoColor=white)

**[ 🇷🇺 Русская документация](#-возможности-ru) &nbsp;|&nbsp; [ 🇬🇧 English Documentation](#-features-en)**

</div>

---

## 🇷🇺 Возможности (RU)

**RDS & FSLogix Control Center** — универсальное десктопное приложение с современным темным интерфейсом (DWM Dark UI) для централизованного мониторинга и администрирования распределенных ферм **Microsoft Remote Desktop Services (RDS)** и файловых серверов хранения контейнеров профилей **FSLogix (Linux / Samba)**.

### ⚡ Ключевой функционал

| Модуль | Описание возможностей |
| :--- | :--- |
| **⚙ Гибкая настройка и AD-поиск** | Встроенный менеджер конфигурации (`⚙ Настройки`) с автопоиском брокеров RDS в Active Directory и сохранением списка ферм/серверов в `%APPDATA%\RDSControlCenter\settings.json`. |
| **🚀 Многопоточный опрос ферм** | Параллельный опрос любого количества брокеров соединений (`RDCB`) через пул потоков `RunspacePool` без зависания интерфейса. |
| **👤 Интеграция с Active Directory** | Автоматическое преобразование логинов в **ФИО, отдел и должность** через быстрый `ADSISearcher` с локальным кэшированием. |
| **▣ Silent Shadow (Без запроса)** | Теневое подключение к сессии в режиме **Управления** (`/control /noConsentPrompt`) или **Наблюдения** с автоматической установкой политики `Shadow = 2` на целевом RDSH. |
| **⚡ Менеджер блокировок FSLogix** | Подключение по SSH к любому Linux/Samba серверу профилей, просмотр заблокированных файлов `.vhdx` (`smbstatus -L`) и точечное снятие зависших блокировок (`kill -9 <PID>`) без перезапуска Samba. |
| **◈ Управление узлами RDSH (Drain)** | Централизованное управление приемом новых подключений на каждом хосте фермы: `Yes` (Разрешены), `NotUntilReboot` (До перезагрузки), `No` (Полный запрет) с резервным применением через WMI и реестр. |
| **⚙ Диспетчер процессов сессии** | Просмотр процессов конкретного пользователя (`SessionID`) с расходом ОЗУ и принудительное завершение (`Kill`) зависших приложений без сброса всей сессии. |
| **🔐 Безопасность (Windows DPAPI)** | Пароли SSH шифруются встроенным криптопровайдером Windows DPAPI и привязываются к профилю текущего администратора. |

### 🛠️ Быстрый старт

1. Запустите `RDSManager.exe` (или соберите его из исходников командой `.\build.ps1`).
2. При первом запуске откроется окно **«⚙ Настройки инфраструктуры»**: нажмите **«🔍 Найти серверы RDS/RDCB в Active Directory»** (или укажите FQDN/IP ваших брокеров вручную) и введите адрес сервера профилей FSLogix.
3. Нажмите **«✔ Сохранить и опросить фермы»**.

---

## 🇬🇧 Features (EN)

**RDS & FSLogix Control Center** is a universal, zero-hardcode Windows Forms administration utility featuring a custom GDI+ Dark UI (`dwmapi.dll`), designed to manage multi-broker **Windows Server RDS** environments and **Linux/Samba-backed FSLogix** profile containers from a single pane of glass.

### ⚡ Key Capabilities

| Feature | Technical Overview |
| :--- | :--- |
| **⚙ Dynamic Config & AD Discovery** | Built-in infrastructure configuration dialog with 1-click Active Directory broker auto-discovery. Stores settings locally in `%APPDATA%\RDSControlCenter\settings.json`. |
| **🚀 Asynchronous Multi-Broker Polling** | Queries multiple RDS Connection Brokers concurrently using PowerShell `RunspacePool` for instant UI responsiveness. |
| **👤 Active Directory Enrichment** | Resolves SAMAccountNames on the fly into **Full Name, Department, and Job Title** via lightweight LDAP `ADSISearcher` caching. |
| **▣ Silent Shadowing (Zero-Prompt)** | Instant 1-click or double-click session shadowing in **Control** or **View-Only** modes (`/noConsentPrompt`), automatically enforcing `Shadow = 2` policy on target RDSH hosts. |
| **⚡ FSLogix VHDX Lock Manager** | Connects via SSH to any Linux/Samba storage node, inspects active `.vhdx` locks (`smbstatus -L`), and terminates orphaned `smbd` PIDs without disrupting other users. |
| **◈ RDSH Node Drain Mode Control** | Manage session host availability across all collections (`Yes` / `NotUntilReboot` / `No`) via `Set-RDSessionHost` with automatic WMI & Registry (`TSServerDrainMode`) failover. |
| **⚙ Per-Session Task Manager** | Inspect real-time memory usage and terminate hung processes scoped strictly to the selected user `SessionID`. |
| **🔐 DPAPI Credential Vault** | SSH credentials are encrypted at rest using Windows Data Protection API (`DPAPI`) tied to the administrator user profile. |

### 📦 Building from Source

Run `./build.ps1` in PowerShell to compile `RDSManager.ps1` into a standalone UAC-elevated executable (`RDSManager.exe`).
