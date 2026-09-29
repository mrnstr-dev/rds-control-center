#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RDS & FSLogix Control Center v4.2 — Native Linux (Ubuntu) Edition
Dark UI (PyQt6) | Multi-Broker WinRM | FSLogix SSH Lock Manager | FreeRDP Shadowing
"""

import sys
import os
import json
import csv
import base64
import socket
import subprocess
from datetime import datetime
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

import winrm
import paramiko
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QTimer
from PyQt6.QtGui import QColor, QFont, QKeySequence, QShortcut, QAction, QClipboard
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QGridLayout,
    QLabel, QPushButton, QLineEdit, QComboBox, QCheckBox, QTableWidget,
    QTableWidgetItem, QHeaderView, QDialog, QTextEdit, QListWidget,
    QMessageBox, QFileDialog, QMenu, QFrame, QInputDialog, QAbstractItemView
)

CONFIG_DIR = Path.home() / ".config" / "RDSControlCenter"
SETTINGS_FILE = CONFIG_DIR / "settings_linux.json"
CONFIG_DIR.mkdir(parents=True, exist_ok=True)

DARK_STYLESHEET = """
QMainWindow, QDialog, QWidget {
    background-color: #0b0f19;
    color: #f1f5f9;
    font-family: 'Segoe UI', 'Ubuntu', 'Noto Sans', sans-serif;
    font-size: 13px;
}
QFrame#SurfacePanel {
    background-color: #111827;
    border-bottom: 1px solid #1e293b;
}
QFrame#KpiCard {
    background-color: #1e293b;
    border: 1px solid #334155;
    border-top: 4px solid #38bdf8;
    border-radius: 4px;
}
QFrame#KpiCard:hover {
    background-color: #2a3850;
    border-color: #38bdf8;
}
QLineEdit, QTextEdit, QListWidget, QComboBox {
    background-color: #0f172a;
    color: #f1f5f9;
    border: 1px solid #38bdf8;
    border-radius: 3px;
    padding: 4px 8px;
}
QPushButton {
    color: #ffffff;
    background-color: #2563eb;
    border: 1px solid #475569;
    border-radius: 3px;
    padding: 6px 10px;
    font-weight: bold;
}
QPushButton:hover {
    background-color: #3b82f6;
}
QPushButton:disabled {
    background-color: #1e293b;
    color: #64748b;
}
QTableWidget {
    background-color: #111827;
    alternate-background-color: #131c31;
    color: #f1f5f9;
    gridline-color: #1e293b;
    border: none;
    selection-background-color: #1e3a8a;
    selection-color: #ffffff;
}
QHeaderView::section {
    background-color: #1e293b;
    color: #38bdf8;
    font-weight: bold;
    padding: 8px;
    border: none;
    border-bottom: 1px solid #334155;
}
QMenu {
    background-color: #0f172a;
    color: #e2e8f0;
    border: 1px solid #334155;
}
QMenu::item:selected {
    background-color: #1e3a8a;
    color: #ffffff;
}
"""


def load_settings() -> dict:
    default = {
        "brokers": [],
        "winrm_user": "",
        "winrm_pass": "",
        "fslogix_host": "",
        "ssh_user": "root",
        "ssh_pass": ""
    }
    if SETTINGS_FILE.exists():
        try:
            data = json.loads(SETTINGS_FILE.read_text(encoding="utf-8"))
            default.update(data)
        except Exception:
            pass
    return default


def save_settings(cfg: dict):
    SETTINGS_FILE.write_text(json.dumps(cfg, indent=2, ensure_ascii=False), encoding="utf-8")
    try:
        os.chmod(SETTINGS_FILE, 0o600)
    except Exception:
        pass


def run_winrm_ps(host: str, user: str, password: str, ps_script: str, timeout: int = 25) -> str:
    """Выполняет PowerShell-скрипт на удаленном Windows-брокере/RDSH через WinRM (NTLM)."""
    s = winrm.Session(
        target=host,
        auth=(user, password),
        transport="ntlm",
        server_cert_validation="ignore",
        read_timeout_sec=timeout,
        operation_timeout_sec=timeout - 3
    )
    res = s.run_ps(ps_script)
    if res.status_code != 0 and not res.std_out:
        err = res.std_err.decode("utf-8", errors="ignore")
        raise RuntimeError(err.strip() or f"WinRM exit code {res.status_code}")
    return res.std_out.decode("utf-8", errors="ignore").strip()


def invoke_ssh_cmd(host: str, user: str, password: str, bash_cmd: str) -> str:
    """Выполняет команду на Linux/Samba сервере FSLogix по SSH."""
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(hostname=host, username=user, password=password, timeout=10)
    try:
        b64 = base64.b64encode(bash_cmd.encode("utf-8")).decode("ascii")
        if user == "root":
            full_cmd = f"echo {b64} | base64 -d | bash"
        else:
            esc = password.replace("'", "'\\''")
            full_cmd = f"echo '{esc}' | sudo -S -p '' bash -c 'echo {b64} | base64 -d | bash'"
        _, stdout, stderr = client.exec_command(full_cmd, timeout=20)
        out = stdout.read().decode("utf-8", errors="ignore")
        return out
    finally:
        client.close()


class KpiCard(QFrame):
    clicked = pyqtSignal()

    def __init__(self, title: str, value: str, sub: str, accent_hex: str):
        super().__init__()
        self.setObjectName("KpiCard")
        self.setCursor(Qt.CursorShape.PointingHandCursor)
        self.setStyleSheet(f"""
            QFrame#KpiCard {{
                background-color: #1e293b;
                border: 1px solid #334155;
                border-top: 4px solid {accent_hex};
                border-radius: 4px;
            }}
            QFrame#KpiCard:hover {{
                background-color: #2a3850;
                border: 1px solid {accent_hex};
                border-top: 4px solid {accent_hex};
            }}
        """)
        lay = QVBoxLayout(self)
        lay.setContentsMargins(14, 8, 14, 8)
        lay.setSpacing(2)

        self.lbl_title = QLabel(title)
        self.lbl_title.setStyleSheet("color: #94a3b8; font-size: 11px; font-weight: bold; background: transparent;")
        self.lbl_val = QLabel(value)
        self.lbl_val.setStyleSheet("color: #f1f5f9; font-size: 23px; font-weight: bold; background: transparent;")
        self.lbl_sub = QLabel(sub)
        self.lbl_sub.setStyleSheet(f"color: {accent_hex}; font-size: 11px; background: transparent;")

        lay.addWidget(self.lbl_title)
        lay.addWidget(self.lbl_val)
        lay.addWidget(self.lbl_sub)

    def mousePressEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            self.clicked.emit()
        super().mousePressEvent(event)


class PollBrokersWorker(QThread):
    finished_data = pyqtSignal(list, int, bool)

    def __init__(self, settings: dict):
        super().__init__()
        self.settings = settings

    def _poll_single_broker(self, broker: str, user: str, password: str) -> dict:
        short_name = broker.split(".")[0]
        ip_addr = ""
        try:
            ip_addr = socket.gethostbyname(broker)
        except Exception:
            return {"broker": broker, "short": short_name, "ip": "", "online": False, "sessions": []}

        # Быстрая проверка порта WinRM (5985) или RPC (135)
        port_ok = False
        for port in (5985, 135):
            try:
                with socket.create_connection((broker, port), timeout=0.6):
                    port_ok = True
                    break
            except Exception:
                pass
        if not port_ok:
            return {"broker": broker, "short": short_name, "ip": ip_addr, "online": False, "sessions": []}

        ps = r"""
$ErrorActionPreference = 'Stop'
Import-Module RemoteDesktop
$sessions = @(Get-RDUserSession -ConnectionBroker '""" + broker + r"""')
$adCache = @{}
$out = foreach ($s in $sessions) {
    $login = [string]$s.UserName
    $clean = $login.Split('\')[-1].ToLower()
    if (-not $adCache.ContainsKey($clean)) {
        $fn = $clean; $deptStr = ""
        try {
            $sr = ([adsisearcher]"(&(objectCategory=person)(objectClass=user)(sAMAccountName=$clean))").FindOne()
            if ($sr) {
                if ($sr.Properties["displayname"].Count -gt 0) { $fn = [string]$sr.Properties["displayname"][0] }
                $d = if ($sr.Properties["department"].Count -gt 0) { [string]$sr.Properties["department"][0] } else { "" }
                $t = if ($sr.Properties["title"].Count -gt 0) { [string]$sr.Properties["title"][0] } else { "" }
                $deptStr = if ($d -and $t) { "$d  •  $t" } elseif ($d) { $d } else { $t }
            }
        } catch {}
        $adCache[$clean] = @{ FullName = $fn; Dept = $deptStr }
    }
    $idle = 0
    if ($null -ne $s.IdleTime) {
        if ($s.IdleTime -is [TimeSpan]) { $idle = [int][Math]::Floor($s.IdleTime.TotalMinutes) }
        elseif ($s.IdleTime -as [double]) { $idle = [int][Math]::Floor(([double]$s.IdleTime) / 60000) }
    }
    $st = switch ([string]$s.SessionState) {
        "STATE_ACTIVE"       { "Активен" }
        "STATE_CONNECTED"    { "Подключен" }
        "STATE_DISCONNECTED" { "Отключен" }
        default              { [string]$s.SessionState }
    }
    $ct = if ($s.CreateTime) { ([datetime]$s.CreateTime).ToString("dd.MM.yyyy HH:mm:ss") } else { "" }
    [PSCustomObject]@{
        UserName       = $login
        FullName       = $adCache[$clean].FullName
        Dept           = $adCache[$clean].Dept
        HostShort      = ([string]$s.HostServer).Split('.')[0]
        HostServerFQDN = [string]$s.HostServer
        SessionState   = $st
        SessionID      = [int]$s.UnifiedSessionId
        CreateTime     = $ct
        IdleMinutes    = $idle
    }
}
ConvertTo-Json -InputObject @($out) -Compress
"""
        try:
            raw_json = run_winrm_ps(broker, user, password, ps)
            parsed = json.loads(raw_json) if raw_json else []
            if isinstance(parsed, dict):
                parsed = [parsed]
            return {"broker": broker, "short": short_name, "ip": ip_addr, "online": True, "sessions": parsed}
        except Exception:
            return {"broker": broker, "short": short_name, "ip": ip_addr, "online": False, "sessions": []}

    def run(self):
        brokers = self.settings.get("brokers", [])
        user = self.settings.get("winrm_user", "")
        pw = self.settings.get("winrm_pass", "")
        fsl_host = self.settings.get("fslogix_host", "")

        ssh_online = False
        if fsl_host:
            try:
                with socket.create_connection((fsl_host, 22), timeout=0.4):
                    ssh_online = True
            except Exception:
                pass

        if not brokers or not user:
            self.finished_data.emit([], 0, ssh_online)
            return

        results = []
        online_brokers = 0
        with ThreadPoolExecutor(max_workers=max(1, len(brokers))) as pool:
            futures = {pool.submit(self._poll_single_broker, b, user, pw): b for b in brokers}
            for fut in as_completed(futures):
                res = fut.result()
                if res["online"]:
                    online_brokers += 1
                results.append(res)

        self.finished_data.emit(results, online_brokers, ssh_online)


class SettingsDialog(QDialog):
    def __init__(self, parent, cfg: dict):
        super().__init__(parent)
        self.setWindowTitle("Настройки инфраструктуры (F12) — RDS WinRM & FSLogix SSH")
        self.resize(640, 540)
        self.cfg = cfg

        lay = QVBoxLayout(self)

        lbl_b = QLabel("Список серверов RD Connection Broker (по одному FQDN или IP на строку):")
        lbl_b.setStyleSheet("color: #38bdf8; font-weight: bold;")
        lay.addWidget(lbl_b)

        self.txt_brokers = QTextEdit()
        self.txt_brokers.setPlainText("\n".join(cfg.get("brokers", [])))
        self.txt_brokers.setFixedHeight(130)
        lay.addWidget(self.txt_brokers)

        lbl_w = QLabel("Учетная запись администратора домена Windows (для WinRM опроса брокеров):")
        lbl_w.setStyleSheet("color: #38bdf8; font-weight: bold;")
        lay.addWidget(lbl_w)

        w_row = QHBoxLayout()
        self.txt_wuser = QLineEdit(cfg.get("winrm_user", ""))
        self.txt_wuser.setPlaceholderText("DOMAIN\\admin_user")
        self.txt_wpass = QLineEdit(cfg.get("winrm_pass", ""))
        self.txt_wpass.setPlaceholderText("Пароль администратора домена")
        self.txt_wpass.setEchoMode(QLineEdit.EchoMode.Password)
        w_row.addWidget(QLabel("Логин:"))
        w_row.addWidget(self.txt_wuser)
        w_row.addWidget(QLabel("Пароль:"))
        w_row.addWidget(self.txt_wpass)
        lay.addLayout(w_row)

        lbl_f = QLabel("Сервер хранения контейнеров профилей FSLogix (Ubuntu / Samba SSH):")
        lbl_f.setStyleSheet("color: #38bdf8; font-weight: bold;")
        lay.addWidget(lbl_f)

        self.txt_fsl = QLineEdit(cfg.get("fslogix_host", ""))
        self.txt_fsl.setPlaceholderText("IP или FQDN сервера FSLogix")
        lay.addWidget(self.txt_fsl)

        s_row = QHBoxLayout()
        self.txt_suser = QLineEdit(cfg.get("ssh_user", "root"))
        self.txt_spass = QLineEdit(cfg.get("ssh_pass", ""))
        self.txt_spass.setEchoMode(QLineEdit.EchoMode.Password)
        self.txt_spass.setPlaceholderText("Пароль SSH / sudo")
        s_row.addWidget(QLabel("SSH Логин:"))
        s_row.addWidget(self.txt_suser)
        s_row.addWidget(QLabel("SSH Пароль:"))
        s_row.addWidget(self.txt_spass)
        lay.addLayout(s_row)

        note = QLabel(f"Настройки сохраняются в {SETTINGS_FILE} (права 0600)")
        note.setStyleSheet("color: #94a3b8; font-size: 11px;")
        lay.addWidget(note)

        btn_row = QHBoxLayout()
        btn_save = QPushButton("✔ Сохранить и опросить фермы")
        btn_save.setStyleSheet("background-color: #059669;")
        btn_cancel = QPushButton("Отмена")
        btn_cancel.setStyleSheet("background-color: #334155;")
        btn_save.clicked.connect(self.save_and_close)
        btn_cancel.clicked.connect(self.reject)
        btn_row.addWidget(btn_save)
        btn_row.addWidget(btn_cancel)
        lay.addLayout(btn_row)

    def save_and_close(self):
        brokers = [line.strip() for line in self.txt_brokers.toPlainText().splitlines() if line.strip()]
        self.cfg["brokers"] = brokers
        self.cfg["winrm_user"] = self.txt_wuser.text().strip()
        self.cfg["winrm_pass"] = self.txt_wpass.text()
        self.cfg["fslogix_host"] = self.txt_fsl.text().strip()
        self.cfg["ssh_user"] = self.txt_suser.text().strip() or "root"
        self.cfg["ssh_pass"] = self.txt_spass.text()
        save_settings(self.cfg)
        self.accept()


class FSLogixDialog(QDialog):
    def __init__(self, parent, cfg: dict, initial_user: str = ""):
        super().__init__(parent)
        self.cfg = cfg
        self.setWindowTitle(f"FSLogix VHDX Lock Manager (F7) — {cfg.get('fslogix_host', '')}")
        self.resize(1080, 540)

        lay = QVBoxLayout(self)
        top = QHBoxLayout()
        top.addWidget(QLabel("Сервер FSLogix:"))
        self.txt_srv = QLineEdit(cfg.get("fslogix_host", ""))
        self.txt_srv.setFixedWidth(160)
        top.addWidget(self.txt_srv)

        top.addWidget(QLabel("Фильтр по логину:"))
        self.txt_filter = QLineEdit(initial_user)
        self.txt_filter.textChanged.connect(self.apply_filter)
        top.addWidget(self.txt_filter)

        btn_scan = QPushButton("⟳ Опросить сервер")
        btn_scan.clicked.connect(self.load_locks)
        btn_unlock = QPushButton("⚡ Разблокировать выбранный VHDX")
        btn_unlock.setStyleSheet("background-color: #b91c1c;")
        btn_unlock.clicked.connect(self.unlock_selected)
        top.addWidget(btn_scan)
        top.addWidget(btn_unlock)
        lay.addLayout(top)

        self.table = QTableWidget(0, 5)
        self.table.setHorizontalHeaderLabels(["PID (smbd)", "Пользователь", "Режим", "Файл контейнера (VHDX)", "Время блокировки"])
        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.table.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.table.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        lay.addWidget(self.table)

        self.lbl_status = QLabel("Готов")
        self.lbl_status.setStyleSheet("color: #38bdf8;")
        lay.addWidget(self.lbl_status)

        self.all_rows = []
        QTimer.singleShot(100, self.load_locks)

    def load_locks(self):
        srv = self.txt_srv.text().strip()
        if not srv:
            return
        self.cfg["fslogix_host"] = srv
        save_settings(self.cfg)
        self.lbl_status.setText(f"Запрос smbstatus -L на {srv}...")
        QApplication.processEvents()

        bash = r"""smbstatus -L -n 2>/dev/null | awk 'NR>3 && NF>=6 && ($0 ~ /\.vhdx|\.VHDX|\.vhd|\.lock|\.meta/) {
            pid=$1; rw=$4;
            match($0, /[A-Z][a-z]{2}[ ]+[A-Z][a-z]{2}[ ]+[0-9]+[ ]+[0-9:]+[ ]+[0-9]{4}/);
            if (RSTART > 0) {
                fpath = substr($0, 1, RSTART-1);
                sub(/^[0-9]+[ ]+[0-9]+[ ]+[A-Z0-9_]+[ ]+[A-Z0-9_]+[ ]+[A-Z0-9_]+[ ]+/, "", fpath);
                gsub(/[ ]+$/, "", fpath);
                ltime = substr($0, RSTART, RLENGTH);
                print pid "|" rw "|" fpath "|" ltime
            }
        }'"""
        try:
            raw = invoke_ssh_cmd(srv, self.cfg.get("ssh_user", "root"), self.cfg.get("ssh_pass", ""), bash)
            self.all_rows = []
            for line in raw.splitlines():
                if "|" not in line:
                    continue
                parts = [p.strip() for p in line.split("|")]
                if len(parts) >= 3:
                    pid_v, rw_v, fpath = parts[0], parts[1], parts[2]
                    t_v = parts[3] if len(parts) >= 4 else ""
                    u_guess = os.path.basename(fpath).replace(".vhdx", "").replace(".VHDX", "")
                    self.all_rows.append((pid_v, u_guess, rw_v, fpath, t_v))
            self.apply_filter()
        except Exception as e:
            QMessageBox.critical(self, "Ошибка SSH", str(e))

    def apply_filter(self):
        q = self.txt_filter.text().strip().lower()
        filtered = [r for r in self.all_rows if not q or q in r[1].lower() or q in r[3].lower()]
        self.table.setRowCount(len(filtered))
        for idx, r in enumerate(filtered):
            for col, val in enumerate(r):
                self.table.setItem(idx, col, QTableWidgetItem(val))
        self.lbl_status.setText(f"Найдено блокировок VHDX: {len(filtered)} (всего: {len(self.all_rows)})")

    def unlock_selected(self):
        rows = {i.row() for i in self.table.selectedIndexes()}
        if not rows:
            return
        pids = list({self.table.item(r, 0).text() for r in rows})
        if QMessageBox.question(self, "Разблокировка VHDX", f"Принудительно закрыть процессы smbd (PID: {', '.join(pids)})?") == QMessageBox.StandardButton.Yes:
            try:
                invoke_ssh_cmd(self.txt_srv.text().strip(), self.cfg["ssh_user"], self.cfg["ssh_pass"], f"kill -9 {' '.join(pids)} 2>/dev/null")
                QMessageBox.information(self, "Успешно", "Блокировка контейнера VHDX снята.")
                self.load_locks()
            except Exception as e:
                QMessageBox.critical(self, "Ошибка", str(e))


class NodesDrainDialog(QDialog):
    def __init__(self, parent, cfg: dict):
        super().__init__(parent)
        self.cfg = cfg
        self.setWindowTitle("Управление узлами сеансов RDSH — Drain Mode (F4)")
        self.resize(1050, 520)

        lay = QVBoxLayout(self)
        top = QHBoxLayout()
        btn_ref = QPushButton("⟳ Обновить узлы")
        btn_yes = QPushButton("✔ Разрешить вход (Yes)")
        btn_yes.setStyleSheet("background-color: #059669;")
        btn_reb = QPushButton("⏸ Запретить до ребута (NotUntilReboot)")
        btn_reb.setStyleSheet("background-color: #b45309;")
        btn_no = QPushButton("✖ Полный запрет (No)")
        btn_no.setStyleSheet("background-color: #b91c1c;")

        btn_ref.clicked.connect(self.load_nodes)
        btn_yes.clicked.connect(lambda: self.set_mode("Yes"))
        btn_reb.clicked.connect(lambda: self.set_mode("NotUntilReboot"))
        btn_no.clicked.connect(lambda: self.set_mode("No"))

        for b in (btn_ref, btn_yes, btn_reb, btn_no):
            top.addWidget(b)
        lay.addLayout(top)

        self.table = QTableWidget(0, 5)
        self.table.setHorizontalHeaderLabels(["Ферма", "Коллекция", "Сервер RDSH", "Новые подключения", "BrokerFQDN"])
        self.table.setColumnHidden(4, True)
        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.table.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.table.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        lay.addWidget(self.table)

        QTimer.singleShot(100, self.load_nodes)

    def load_nodes(self):
        self.table.setRowCount(0)
        for broker in self.cfg.get("brokers", []):
            ps = f"""
Import-Module RemoteDesktop -ErrorAction Stop
$colls = @(Get-RDSessionCollection -ConnectionBroker '{broker}' -ErrorAction SilentlyContinue)
$out = foreach ($c in $colls) {{
    $hosts = @(Get-RDSessionHost -CollectionName $c.CollectionName -ConnectionBroker '{broker}')
    foreach ($h in $hosts) {{
        [PSCustomObject]@{{
            Collection = [string]$c.CollectionName
            HostFQDN   = [string]$h.SessionHost
            Mode       = [string]$h.NewConnectionAllowed
        }}
    }}
}}
ConvertTo-Json -InputObject @($out) -Compress
"""
            try:
                raw = run_winrm_ps(broker, self.cfg["winrm_user"], self.cfg["winrm_pass"], ps)
                items = json.loads(raw) if raw else []
                if isinstance(items, dict):
                    items = [items]
                for it in items:
                    r = self.table.rowCount()
                    self.table.insertRow(r)
                    self.table.setItem(r, 0, QTableWidgetItem(broker.split(".")[0]))
                    self.table.setItem(r, 1, QTableWidgetItem(it.get("Collection", "")))
                    self.table.setItem(r, 2, QTableWidgetItem(it.get("HostFQDN", "")))
                    self.table.setItem(r, 3, QTableWidgetItem(it.get("Mode", "")))
                    self.table.setItem(r, 4, QTableWidgetItem(broker))
            except Exception:
                pass

    def set_mode(self, mode: str):
        rows = {i.row() for i in self.table.selectedIndexes()}
        if not rows:
            return
        for r in rows:
            host_fqdn = self.table.item(r, 2).text()
            broker = self.table.item(r, 4).text()
            ps = f"Import-Module RemoteDesktop; Set-RDSessionHost -SessionHost '{host_fqdn}' -NewConnectionAllowed {mode} -ConnectionBroker '{broker}'"
            try:
                run_winrm_ps(broker, self.cfg["winrm_user"], self.cfg["winrm_pass"], ps)
            except Exception as e:
                QMessageBox.warning(self, "Ошибка", str(e))
        self.load_nodes()


class CollectionGroupsDialog(QDialog):
    def __init__(self, parent, cfg: dict):
        super().__init__(parent)
        self.cfg = cfg
        self.setWindowTitle("Доступ к коллекциям RDS — Доменные группы AD (F6)")
        self.resize(1100, 540)

        lay = QHBoxLayout(self)
        left = QVBoxLayout()
        btn_ref = QPushButton("⟳ Обновить коллекции со всех ферм")
        btn_ref.clicked.connect(self.load_collections)
        left.addWidget(btn_ref)

        self.table = QTableWidget(0, 4)
        self.table.setHorizontalHeaderLabels(["Ферма", "Коллекция", "Разрешенные группы (UserGroup)", "BrokerFQDN"])
        self.table.setColumnHidden(3, True)
        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.table.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.table.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        self.table.itemSelectionChanged.connect(self.sync_groups_list)
        left.addWidget(self.table)
        lay.addLayout(left, 3)

        right = QVBoxLayout()
        right.addWidget(QLabel("ГРУППЫ ВЫБРАННОЙ КОЛЛЕКЦИИ:"))
        self.lst_groups = QListWidget()
        right.addWidget(self.lst_groups)

        add_row = QHBoxLayout()
        self.txt_new_grp = QLineEdit()
        self.txt_new_grp.setPlaceholderText("DOMAIN\\GroupName")
        btn_add = QPushButton("+ Добавить")
        btn_add.clicked.connect(self.add_group)
        add_row.addWidget(self.txt_new_grp)
        add_row.addWidget(btn_add)
        right.addLayout(add_row)

        btn_del = QPushButton("✖ Удалить выбранную группу")
        btn_del.setStyleSheet("background-color: #b91c1c;")
        btn_del.clicked.connect(self.del_group)
        right.addWidget(btn_del)

        btn_save = QPushButton("✔ Сохранить права доступа на брокере")
        btn_save.setStyleSheet("background-color: #059669;")
        btn_save.clicked.connect(self.save_groups)
        right.addWidget(btn_save)
        lay.addLayout(right, 2)

        QTimer.singleShot(100, self.load_collections)

    def load_collections(self):
        self.table.setRowCount(0)
        for broker in self.cfg.get("brokers", []):
            ps = f"""
Import-Module RemoteDesktop -ErrorAction Stop
$colls = @(Get-RDSessionCollection -ConnectionBroker '{broker}')
$out = foreach ($c in $colls) {{
    $cfg = Get-RDSessionCollectionConfiguration -CollectionName $c.CollectionName -UserGroup -ConnectionBroker '{broker}'
    [PSCustomObject]@{{
        Collection = [string]$c.CollectionName
        Groups     = (@($cfg.UserGroup) -join '; ')
    }}
}}
ConvertTo-Json -InputObject @($out) -Compress
"""
            try:
                raw = run_winrm_ps(broker, self.cfg["winrm_user"], self.cfg["winrm_pass"], ps)
                items = json.loads(raw) if raw else []
                if isinstance(items, dict):
                    items = [items]
                for it in items:
                    r = self.table.rowCount()
                    self.table.insertRow(r)
                    self.table.setItem(r, 0, QTableWidgetItem(broker.split(".")[0]))
                    self.table.setItem(r, 1, QTableWidgetItem(it.get("Collection", "")))
                    self.table.setItem(r, 2, QTableWidgetItem(it.get("Groups", "")))
                    self.table.setItem(r, 3, QTableWidgetItem(broker))
            except Exception:
                pass

    def sync_groups_list(self):
        self.lst_groups.clear()
        rows = {i.row() for i in self.table.selectedIndexes()}
        if not rows:
            return
        r = list(rows)[0]
        grps = self.table.item(r, 2).text()
        for g in grps.split(";"):
            if g.strip():
                self.lst_groups.addItem(g.strip())

    def add_group(self):
        g = self.txt_new_grp.text().strip()
        if g:
            self.lst_groups.addItem(g)
            self.txt_new_grp.clear()

    def del_group(self):
        for item in self.lst_groups.selectedItems():
            self.lst_groups.takeItem(self.lst_groups.row(item))

    def save_groups(self):
        rows = {i.row() for i in self.table.selectedIndexes()}
        if not rows:
            return
        r = list(rows)[0]
        col_name = self.table.item(r, 1).text()
        broker = self.table.item(r, 3).text()
        groups = [self.lst_groups.item(i).text() for i in range(self.lst_groups.count())]
        if not groups:
            return
        arr_str = ",".join([f"'{g}'" for g in groups])
        ps = f"Import-Module RemoteDesktop; Set-RDSessionCollectionConfiguration -CollectionName '{col_name}' -UserGroup @({arr_str}) -ConnectionBroker '{broker}'"
        try:
            run_winrm_ps(broker, self.cfg["winrm_user"], self.cfg["winrm_pass"], ps)
            QMessageBox.information(self, "Успешно", f"Группы коллекции '{col_name}' обновлены.")
            self.load_collections()
        except Exception as e:
            QMessageBox.critical(self, "Ошибка", str(e))


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("RDS & FSLogix Control Center v4.2 — Linux Edition")
        self.resize(1600, 850)
        self.settings = load_settings()
        self.all_sessions = []

        central = QWidget()
        self.setCentralWidget(central)
        main_lay = QVBoxLayout(central)
        main_lay.setContentsMargins(10, 10, 10, 6)
        main_lay.setSpacing(8)

        # 1. Верхние KPI карточки
        kpi_lay = QHBoxLayout()
        self.card_total = KpiCard("ВСЕГО СЕССИЙ", "—", "▸ Показать все сессии", "#38bdf8")
        self.card_active = KpiCard("АКТИВНЫЕ СЕССИИ", "—", "● Работают сейчас (фильтр)", "#22c55e")
        self.card_disc = KpiCard("ОТКЛЮЧЕННЫЕ (IDLE)", "—", "○ Ждут переподключения", "#f59e0b")
        self.card_brokers = KpiCard("УЗЛЫ И БРОКЕРЫ", "—", "◈ Узлы RDSH (F4) / Коллекции (F6)", "#a855f7")
        self.card_fsl = KpiCard("FSLOGIX СЕРВЕР", self.settings.get("fslogix_host") or "Не задан", "⚡ Блокировки VHDX (F7)", "#38bdf8")

        self.card_total.clicked.connect(lambda: self.cb_state.setCurrentIndex(0))
        self.card_active.clicked.connect(lambda: self.cb_state.setCurrentIndex(1))
        self.card_disc.clicked.connect(lambda: self.cb_state.setCurrentIndex(2))
        self.card_brokers.clicked.connect(self.open_nodes_manager)
        self.card_fsl.clicked.connect(self.open_fslogix_manager)

        for c in (self.card_total, self.card_active, self.card_disc, self.card_brokers, self.card_fsl):
            kpi_lay.addWidget(c)
        main_lay.addLayout(kpi_lay)

        # 2. Панель кнопок F2..F12
        tool_frame = QFrame()
        tool_frame.setObjectName("SurfacePanel")
        tool_lay = QVBoxLayout(tool_frame)
        btn_row = QHBoxLayout()

        self.btn_ref = self._mk_btn("⟳ Обновить (F5)", "#2563eb", self.refresh_sessions)
        self.btn_sh_ctrl = self._mk_btn("▣ Управление (F2)", "#059669", lambda: self.start_shadow(True))
        self.btn_sh_view = self._mk_btn("◉ Наблюдение (F3)", "#0d9488", lambda: self.start_shadow(False))
        self.btn_nodes = self._mk_btn("◈ Узлы RDSH (F4)", "#1e40af", self.open_nodes_manager)
        self.btn_colls = self._mk_btn("★ Коллекции (F6)", "#6d28d9", self.open_collections_manager)
        self.btn_fsl = self._mk_btn("⚡ FSLogix (F7)", "#7e22ce", self.open_fslogix_manager)
        self.btn_procs = self._mk_btn("⚙ Процессы (F8)", "#4338ca", self.open_processes_dialog)
        self.btn_msg = self._mk_btn("✉ Сообщение (F9)", "#0369a1", self.send_message_action)
        self.btn_disc = self._mk_btn("⏸ Отключить (F10)", "#b45309", self.disconnect_action)
        self.btn_logoff = self._mk_btn("✖ Сбросить (F11)", "#b91c1c", self.logoff_action)
        self.btn_csv = self._mk_btn("⤓ CSV (^S)", "#334155", self.export_csv)
        self.btn_cfg = self._mk_btn("⚙ Настройки (F12)", "#1e293b", self.open_settings)

        for b in (self.btn_ref, self.btn_sh_ctrl, self.btn_sh_view, self.btn_nodes, self.btn_colls,
                  self.btn_fsl, self.btn_procs, self.btn_msg, self.btn_disc, self.btn_logoff, self.btn_csv, self.btn_cfg):
            btn_row.addWidget(b)
        tool_lay.addLayout(btn_row)

        # Ряд фильтров
        flt_row = QHBoxLayout()
        flt_row.addWidget(QLabel("ФЕРМА:"))
        self.cb_brokers = QComboBox()
        self.cb_brokers.setFixedWidth(200)
        self.cb_brokers.currentIndexChanged.connect(self.apply_filters)
        flt_row.addWidget(self.cb_brokers)

        flt_row.addWidget(QLabel("СТАТУС:"))
        self.cb_state = QComboBox()
        self.cb_state.addItems(["Все сессии", "Только Активные", "Только Отключенные"])
        self.cb_state.currentIndexChanged.connect(self.apply_filters)
        flt_row.addWidget(self.cb_state)

        flt_row.addWidget(QLabel("ПОИСК (Ctrl+F):"))
        self.txt_search = QLineEdit()
        self.txt_search.setPlaceholderText("Логин, ФИО, отдел, сервер RDSH...")
        self.txt_search.textChanged.connect(self.apply_filters)
        flt_row.addWidget(self.txt_search)

        tool_lay.addLayout(flt_row)
        main_lay.addWidget(tool_frame)

        # 3. Таблица сессий
        self.table = QTableWidget(0, 12)
        self.table.setHorizontalHeaderLabels([
            "Ферма", "IP брокера", "Логин", "ФИО (AD)", "Отдел / Должность",
            "Сервер RDSH", "Статус", "ID", "Время входа", "Простой (мин)",
            "BrokerHost", "HostServerFQDN"
        ])
        self.table.setColumnHidden(10, True)
        self.table.setColumnHidden(11, True)
        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.table.setAlternatingRowColors(True)
        self.table.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.table.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers)
        self.table.doubleClicked.connect(lambda: self.start_shadow(True))
        main_lay.addWidget(self.table)

        # Статус-бар
        self.lbl_status = QLabel("Готов к работе")
        self.lbl_status.setStyleSheet("color: #94a3b8; padding: 4px;")
        main_lay.addWidget(self.lbl_status)

        self._bind_hotkeys()
        self._update_broker_combo()

        if not self.settings.get("brokers"):
            QTimer.singleShot(200, self.open_settings)
        else:
            QTimer.singleShot(200, self.refresh_sessions)

    def _mk_btn(self, text: str, bg: str, slot):
        b = QPushButton(text)
        b.setStyleSheet(f"QPushButton {{ background-color: {bg}; }}")
        b.clicked.connect(slot)
        return b

    def _bind_hotkeys(self):
        shortcuts = [
            ("F2", lambda: self.start_shadow(True)),
            ("F3", lambda: self.start_shadow(False)),
            ("F4", self.open_nodes_manager),
            ("F5", self.refresh_sessions),
            ("F6", self.open_collections_manager),
            ("F7", self.open_fslogix_manager),
            ("F8", self.open_processes_dialog),
            ("F9", self.send_message_action),
            ("F10", self.disconnect_action),
            ("F11", self.logoff_action),
            ("F12", self.open_settings),
            ("Ctrl+S", self.export_csv),
            ("Ctrl+F", lambda: self.txt_search.setFocus()),
        ]
        for key, fn in shortcuts:
            sc = QShortcut(QKeySequence(key), self)
            sc.activated.connect(fn)

    def _update_broker_combo(self):
        self.cb_brokers.blockSignals(True)
        self.cb_brokers.clear()
        self.cb_brokers.addItem("Все брокеры")
        for b in self.settings.get("brokers", []):
            self.cb_brokers.addItem(b.split(".")[0])
        self.cb_brokers.blockSignals(False)

    def open_settings(self):
        dlg = SettingsDialog(self, self.settings)
        if dlg.exec() == QDialog.DialogCode.Accepted:
            self._update_broker_combo()
            self.card_fsl.lbl_val.setText(self.settings.get("fslogix_host") or "Не задан")
            self.refresh_sessions()

    def refresh_sessions(self):
        if not self.settings.get("brokers"):
            self.lbl_status.setText("Нажмите F12, чтобы указать список брокеров RDS и учетные данные WinRM.")
            return
        self.btn_ref.setEnabled(False)
        self.btn_ref.setText("⟳ Загрузка...")
        self.lbl_status.setText("Параллельный опрос брокеров по WinRM...")
        self.worker = PollBrokersWorker(self.settings)
        self.worker.finished_data.connect(self.on_sessions_loaded)
        self.worker.start()

    def on_sessions_loaded(self, results: list, online_count: int, ssh_online: bool):
        self.btn_ref.setEnabled(True)
        self.btn_ref.setText("⟳ Обновить (F5)")
        self.all_sessions = []
        active_cnt = 0
        disc_cnt = 0

        for res in results:
            for s in res.get("sessions", []):
                st = s.get("SessionState", "")
                if st == "Активен":
                    active_cnt += 1
                else:
                    disc_cnt += 1
                self.all_sessions.append({
                    "farm": res["short"],
                    "ip": res["ip"],
                    "login": s.get("UserName", ""),
                    "fio": s.get("FullName", ""),
                    "dept": s.get("Dept", ""),
                    "rdsh": s.get("HostShort", ""),
                    "state": st,
                    "id": str(s.get("SessionID", "")),
                    "time": s.get("CreateTime", ""),
                    "idle": str(s.get("IdleMinutes", 0)),
                    "broker": res["broker"],
                    "rdsh_fqdn": s.get("HostServerFQDN", "")
                })

        self.card_total.lbl_val.setText(str(len(self.all_sessions)))
        self.card_active.lbl_val.setText(str(active_cnt))
        self.card_disc.lbl_val.setText(str(disc_cnt))
        self.card_brokers.lbl_val.setText(f"{online_count} / {len(self.settings.get('brokers', []))}")
        self.card_fsl.lbl_sub.setText("● SSH ОНЛАЙН (F7)" if ssh_online else "○ Нет ответа SSH (F7)")

        self.apply_filters()

    def apply_filters(self):
        farm_flt = self.cb_brokers.currentText() if self.cb_brokers.currentIndex() > 0 else ""
        st_idx = self.cb_state.currentIndex()
        q = self.txt_search.text().strip().lower()

        filtered = []
        for s in self.all_sessions:
            if farm_flt and s["farm"] != farm_flt:
                continue
            if st_idx == 1 and s["state"] != "Активен":
                continue
            if st_idx == 2 and s["state"] == "Активен":
                continue
            if q and not any(q in s[k].lower() for k in ("login", "fio", "dept", "rdsh", "ip")):
                continue
            filtered.append(s)

        self.table.setRowCount(len(filtered))
        for r_idx, s in enumerate(filtered):
            vals = [s["farm"], s["ip"], s["login"], s["fio"], s["dept"], s["rdsh"], s["state"], s["id"], s["time"], s["idle"], s["broker"], s["rdsh_fqdn"]]
            for c_idx, val in enumerate(vals):
                item = QTableWidgetItem(val)
                if c_idx == 6:
                    item.setForeground(QColor("#4ade80") if val == "Активен" else QColor("#94a3b8"))
                self.table.setItem(r_idx, c_idx, item)

        self.lbl_status.setText(f"Отображено сессий: {len(filtered)} из {len(self.all_sessions)}  |  Обновлено: {datetime.now().strftime('%H:%M:%S')}")

    def _selected_rows_data(self) -> list:
        rows = sorted({i.row() for i in self.table.selectedIndexes()})
        out = []
        for r in rows:
            out.append({
                "id": self.table.item(r, 7).text(),
                "broker": self.table.item(r, 10).text(),
                "rdsh": self.table.item(r, 11).text(),
                "login": self.table.item(r, 2).text(),
                "fio": self.table.item(r, 3).text()
            })
        return out

    def start_shadow(self, control: bool):
        sel = self._selected_rows_data()
        if not sel:
            return
        target = sel[0]
        user = self.settings.get("winrm_user", "")
        pw = self.settings.get("winrm_pass", "")
        dom = user.split("\\")[0] if "\\" in user else ""
        usr = user.split("\\")[-1]

        # Запускаем FreeRDP (xfreerdp) на Ubuntu
        cmd = [
            "xfreerdp",
            f"/v:{target['rdsh']}",
            f"/u:{usr}",
            f"/p:{pw}",
            "/cert:ignore",
            "/dynamic-resolution",
            f"/title:Shadow {target['fio']} ({target['rdsh']})"
        ]
        if dom:
            cmd.append(f"/d:{dom}")
        try:
            subprocess.Popen(cmd)
        except FileNotFoundError:
            QMessageBox.warning(self, "FreeRDP не найден", "Установите пакет freerdp2-x11:\nsudo apt install freerdp2-x11")

    def open_nodes_manager(self):
        NodesDrainDialog(self, self.settings).exec()

    def open_collections_manager(self):
        CollectionGroupsDialog(self, self.settings).exec()

    def open_fslogix_manager(self):
        sel = self._selected_rows_data()
        u = sel[0]["login"].split("\\")[-1] if sel else ""
        FSLogixDialog(self, self.settings, u).exec()

    def open_processes_dialog(self):
        sel = self._selected_rows_data()
        if not sel:
            return
        t = sel[0]
        ps = f"Get-CimInstance Win32_Process -Filter 'SessionId = {t['id']}' | Select-Object ProcessId, Name, @{{N='MB';E={{[math]::Round($_.WorkingSetSize/1MB,1)}}}} | ConvertTo-Json -Compress"
        try:
            raw = run_winrm_ps(t["rdsh"], self.settings["winrm_user"], self.settings["winrm_pass"], ps)
            procs = json.loads(raw) if raw else []
            if isinstance(procs, dict):
                procs = [procs]
            items = [f"{p['ProcessId']} | {p['Name']} ({p['MB']} MB)" for p in procs]
            chosen, ok = QInputDialog.getItem(self, f"Процессы: {t['fio']}", "Выберите процесс для завершения (Kill):", items, 0, False)
            if ok and chosen:
                pid = chosen.split("|")[0].strip()
                run_winrm_ps(t["rdsh"], self.settings["winrm_user"], self.settings["winrm_pass"], f"Stop-Process -Id {pid} -Force")
                QMessageBox.information(self, "Успешно", f"Процесс PID {pid} завершен.")
        except Exception as e:
            QMessageBox.warning(self, "Ошибка WinRM", str(e))

    def send_message_action(self):
        sel = self._selected_rows_data()
        if not sel:
            return
        msg, ok = QInputDialog.getText(self, "Отправка сообщения (F9)", f"Текст сообщения ({len(sel)} польз.):")
        if ok and msg:
            for s in sel:
                ps = f"Import-Module RemoteDesktop; Send-RDUserMessage -ConnectionBroker '{s['broker']}' -UnifiedSessionId {s['id']} -MessageTitle 'Сообщение от Администратора' -MessageBody '{msg}'"
                try:
                    run_winrm_ps(s["broker"], self.settings["winrm_user"], self.settings["winrm_pass"], ps)
                except Exception:
                    pass

    def disconnect_action(self):
        sel = self._selected_rows_data()
        if not sel:
            return
        if QMessageBox.question(self, "Отключение (F10)", f"Отключить выбранные сессии ({len(sel)} шт.)?") == QMessageBox.StandardButton.Yes:
            for s in sel:
                try:
                    run_winrm_ps(s["rdsh"], self.settings["winrm_user"], self.settings["winrm_pass"], f"tsdiscon {s['id']}")
                except Exception:
                    pass
            self.refresh_sessions()

    def logoff_action(self):
        sel = self._selected_rows_data()
        if not sel:
            return
        if QMessageBox.question(self, "Сброс сессий (F11)", f"Принудительно завершить сессии ({len(sel)} шт.)?") == QMessageBox.StandardButton.Yes:
            for s in sel:
                try:
                    run_winrm_ps(s["rdsh"], self.settings["winrm_user"], self.settings["winrm_pass"], f"logoff {s['id']}")
                except Exception:
                    pass
            self.refresh_sessions()

    def export_csv(self):
        path, _ = QFileDialog.getSaveFileName(self, "Экспорт CSV", f"RDS_Sessions_{datetime.now().strftime('%Y-%m-%d_%H-%M')}.csv", "CSV (*.csv)")
        if path:
            with open(path, "w", newline="", encoding="utf-8") as f:
                w = csv.writer(f, delimiter=";")
                w.writerow(["Ферма", "IP брокера", "Логин", "ФИО", "Отдел", "Сервер RDSH", "Статус", "ID", "Время входа", "Простой (мин)"])
                for r in range(self.table.rowCount()):
                    w.writerow([self.table.item(r, c).text() for c in range(10)])
            QMessageBox.information(self, "Экспорт CSV", f"Сохранено: {path}")


if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyleSheet(DARK_STYLESHEET)
    win = MainWindow()
    win.show()
    sys.exit(app.exec())
