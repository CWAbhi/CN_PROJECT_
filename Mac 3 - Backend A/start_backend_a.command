#!/bin/zsh
set -e
cd "$(dirname "$0")"
set -a
source ./settings.env
set +a
exec /usr/bin/python3 backend_a.py
