#!/bin/bash
# Script to install and set up VigilPay for mobile access

set -e

echo "Creating virtual environment..."
python -m venv .venv

echo "Activating virtual environment..."
source .venv/bin/activate

echo "Upgrading pip and installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo "Copying example env file (if exists)"
if [ -f .env.example ]; then
  cp .env.example .env
  echo ".env file created from .env.example, please edit as needed."
fi

echo "Running migrations..."
python manage.py migrate

echo "Creating superuser (interactive)..."
python manage.py createsuperuser

echo "Starting development server on 0.0.0.0:8000"
python manage.py runserver 0.0.0.0:8000
