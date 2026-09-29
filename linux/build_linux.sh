#!/usr/bin/env bash
set -e

echo "=== Установка системных пакетов для Ubuntu/Debian ==="
sudo apt-get update
sudo apt-get install -y python3 python3-venv python3-pip freerdp2-x11 libxcb-cursor0

echo "=== Создание виртуального окружения и сборка бинарника ==="
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

pyinstaller --noconfirm --onefile --windowed --name "RDSManager-Linux-x86_64" rds_manager_linux.py

echo "=== Готово! Исполняемый файл: ./dist/RDSManager-Linux-x86_64 ==="
