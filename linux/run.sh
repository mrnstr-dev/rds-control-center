#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

if [ ! -d ".venv" ]; then
    echo "Первый запуск: подготовка окружения Python и FreeRDP..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-venv python3-pip libxcb-cursor0 libxcb-xinerama0 libxkbcommon-x11-0 libegl1
    sudo apt-get install -y freerdp2-x11 || sudo apt-get install -y freerdp3-x11
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
else
    source .venv/bin/activate
fi

nohup python3 rds_manager_linux.py >/dev/null 2>&1 &
echo "RDS & FSLogix Control Center запущен!"
